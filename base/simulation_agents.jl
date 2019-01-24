
include("world_util.jl")

function costs_stay!(agent, loc :: Location, par)
	agent.capital += par.ben_resources * loc.resources - par.costs_stay
end


function costs_move!(agent, link :: Link, par)
	agent.capital -= par.costs_move * link.friction
end


function quality(link :: InfoLink, loc :: InfoLocation, par)
	quality(loc, par) / (1.0 + friction(link)*par.qual_weight_frict)
end

function quality(loc :: InfoLocation, par)
	discounted(loc.quality) + loc.pos.x*par.qual_weight_x + 
		discounted(loc.resources)*par.qual_weight_trust
end

# TODO properties of waystations
function quality(plan :: Vector{InfoLocation}, par)
	if length(plan) == 2
		return quality(find_link(plan[2], plan[1]), plan[1], par)
	end

	# start out with quality of target
	q = quality(plan[1],  par)

	f = 0.0
	for i in 1:length(plan)-1
		f += find_link(plan[i], plan[i+1]).friction.value
	end

	q / (1.0 + f * par.qual_weight_frict)
end


function plan!(agent, par)
	if agent.info_target == []
		agent.plan = []
	else
		agent.plan, count = Pathfinding.path_Astar(info_current(agent), agent.info_target, 
			path_costs, path_costs_estimate, each_neighbour)
	end

	# no plan, try to find better position at least
	# chose random location with prob prop. to quality

	loc = info_current(agent)

	quals = fill(0.0, length(loc.links)+1)
	quals[1] = quality(loc, par)

	for i in eachindex(loc.links)
		q = quality(loc.links[i], otherside(loc.links[i], loc), par)
		@assert !isnan(q)
		quals[i+1] = quals[i] + q
	end

	# plan goes into the choice as well
	if agent.plan != []
		push!(quals, quality(agent.plan, par) + quals[end])
	end

	r = rand() * (quals[end] - 0.0001)
	# -1 because first el is stay
	best = findfirst(x -> x>r, quals) - 1

	# either stay or use planned path
	if best == 0 ||
		(best == length(quals) - 1 && agent.plan != [])
		return agent
	end

	# go to a neighbouring location 
	agent.plan = [otherside(loc.links[best], loc), loc]

	agent
end


function step_agent!(agent::Agent, model::Model, par)
	if decide_stay(agent, par)
		step_agent_stay!(agent, model.world, par)
	else
		step_agent_move!(agent, model.world, par)
	end

	step_agent_info!(agent, model, par)
end


function decide_stay(agent, par)
	return agent.in_transit || agent.plan == []
end


function decide_move(agent::Agent, world::World, par)
	# end is current location
	world.cities[agent.plan[end-1].id]
end


function step_agent_move!(agent, world, par)
	agent.in_transit = true

	loc = decide_move(agent, world, par)

	link = find_link(agent.loc, loc)
	link.count += 1

#	println("a: ", agent.loc.id, " -> ", loc.id) 

	costs_move!(agent, link, par)
	explore_move!(agent, world, loc, par)
	move!(world, agent, loc)
	# TODO find better solution
	pop!(agent.plan)
end


function step_agent_stay!(agent, world, par)
	agent.in_transit = false
	costs_stay!(agent, agent.loc, par)
	explore_stay!(agent, world, par)
	mingle!(agent, agent.loc, world, par)
	plan!(agent, par)
end


# explore while staying at a location
function explore_stay!(agent, world, par)
	explore_at!(agent, world, agent.loc, 1.0, true, par)
end

# explore while moving one step
function explore_move!(agent, world, dest, par)
	info_loc2 :: InfoLocation, l = explore_at!(agent, world, dest, 0.5, false, par)
	info_loc1 :: InfoLocation = info_current(agent)

	link = find_link(agent.loc, dest)
	inf = info(agent, link)
	if inf == UnknownLink
		# TODO stochastic error
		inf = discover!(agent, link, agent.loc, par)
	end

	inf.friction = TrustedF(link.friction, par.trust_travelled)

	agent
end


# connect loc and link (if not already connected)
function connect!(loc :: InfoLocation, link :: InfoLink)
	
	# *** add location to link
	loc_connected = link.l1 == loc || link.l2 == loc
	free_slot = link.l1 == Unknown || link.l2 == Unknown

	if ! loc_connected
		if ! free_slot
			error("Error: Trying to connect a fully connected link!")
		else	
			# link not connected yet, has free slot
			if link.l1 == Unknown
				link.l1 = loc
			else
				link.l2 = loc
			end

			loc_o = otherside(link, loc)
			if loc_o != Unknown
				add_neighbour!(loc_o, loc)
			end
		end
	end

	# *** add link to location

	found = 0

	if ! (link in loc.links)
		add_link!(loc, link)
		loc_o = otherside(link, loc)
		if loc_o != Unknown
			add_neighbour!(loc, loc_o)
		end
	end
end


# add new location to agent (based on world info)
# connect to existing links
function discover!(agent, loc :: Location, par)
	# agents start off with expected values
	inf = InfoLocation(loc.pos, loc.id, TrustedF(par.res_exp, 0.0), TrustedF(par.qual_exp, 0.0), [], [])
	# add location info to agent
	add_info!(agent, inf, loc.typ)
	# connect existing link infos
	for link in loc.links
		info_link = info(agent, link)

		# links to exit are always known
		if info_link == UnknownLink
			if loc.typ != EXIT
				lo = otherside(link, loc)
				if lo.typ == EXIT && info(agent, lo) != Unknown
					discover!(agent, link, loc, par)
				end
			end
		# connect known links
		else				
			connect!(inf, info_link)
		end
	end

	inf	
end	


# add new link to agent (based on world info)
# connect to existing location
function discover!(agent, link :: Link, from :: Location, par)
	info_from = info(agent, from)
	@assert info_from != Unknown
	info_to = info(agent, otherside(link, from))
	info_link = InfoLink(link.id, info_from, info_to, TrustedF(par.frict_exp[Int(link.typ)], 0.0))
	add_info!(agent, info_link)
	# TODO lots of redundancy, possibly join/extend
	connect!(info_from, info_link)
	if info_to != Unknown
		connect!(info_to, info_link)
	end

	info_link	
end


# add new link as a copy from existing one (from other agent)
# currently requires that both endpoints are known
function maybe_learn!(agent, link_orig :: InfoLink)
	# get corresponding loc info from naive individual
	l1_info = agent.info_loc[link_orig.l1.id] 
	l2_info = agent.info_loc[link_orig.l2.id] 

	# check if the agent knows both end points, otherwise abort
	if l1_info == Unknown || l2_info == Unknown
		return UnknownLink	
	end

	info_link = InfoLink(link_orig.id, l1_info, l2_info, link_orig.friction)
	add_info!(agent, info_link)
	connect!(l1_info, info_link)
	connect!(l2_info, info_link)

	info_link
end


function explore_at!(agent, world, loc :: Location, speed, allow_indirect, par)
	# knowledge
	inf = info(agent, loc)
	
	if inf == Unknown
		inf = discover!(agent, loc, par)
	end

	# gain information on local properties
	# stochasticity?
	inf.resources = update(inf.resources, loc.resources, speed)
	inf.quality = update(inf.quality, loc.quality, speed)

	# only location, no links
	if ! allow_indirect
		return inf, loc
	end
	# gain info on links and linked locations
	
	for link in loc.links
		info_link = info(agent, link)

		if info_link == UnknownLink && rand() < par.p_find_links
			info_link = discover!(agent, link, loc, par)

			# TODO imperfect knowledge

			info_link.friction = TrustedF(link.friction, par.trust_found_links)
			
			# no info, but position is known
			explore_at!(agent, world, otherside(link, loc), 0.0, false, par)
		end

		# we might get info on connected location
		if info_link != Unknown && rand() < par.p_find_dests
			explore_at!(agent, world, otherside(link, loc), 0.5, false, par)
		end
	end

	inf, loc
end


# TODO parameterize
# meet other agents, gain contacts and information
function mingle!(agent, location, world, par)
	for a in location.people
		if a == agent
			continue
		end

		# agents keep in contact
		if rand() < par.p_keep_contact
			if (length(agent.contacts)) < par.n_contacts_max
				add_contact!(agent, a)
			end
			if (length(a.contacts)) < par.n_contacts_max
				add_contact!(a, agent)
			end
		end
		
		if rand() < par.p_info_mingle
			exchange_info!(agent, a, world, par)
		end
	end
end

function consensus(val1::TrustedF, val2::TrustedF) :: TrustedF
	sum_t = max(val1.trust + val2.trust, 0.0001)
	v = (discounted(val1) + discounted(val2)) / sum_t
	t = max(val1.trust, val2.trust)

	TrustedF(v, t)
end


# TODO arrived agents don't update their info

function exchange_info!(a1::Agent, a2::Agent, world::World, par)

	# a1 can never have arrived yet
	arr = arrived(a2)

	for l in eachindex(a1.info_loc)
		
		info1 :: InfoLocation = a1.info_loc[l]
		info2 :: InfoLocation = a2.info_loc[l]

		# neither agent knows anything
		if info1 == Unknown && info2 == Unknown
			continue
		end
		
		# both have knowledge at l, compare by trust and transfer accordingly
		if info1 != Unknown && info2 != Unknown
			res_cons = consensus(info1.resources, info2.resources)
			info1.resources = res_cons
			info2.resources = arr ? average(info2.resources, res_cons) : res_cons
			qual_cons = consensus(info1.quality, info2.quality)
			info1.quality = qual_cons
			info2.quality = arr ? average(info2.quality, qual_cons) : qual_cons
			continue
		end

		# not pretty but otherwise we would have to essentially duplicate discover
		# TODO transfer knowledge
		loc = world.cities[l]
		if info2 == Unknown 
			discover!(a2, loc, par)
		else # info1 == Unknown
			discover!(a1, loc, par)
		end
	end

	for l in eachindex(a1.info_link)
		
		info1 :: InfoLink = a1.info_link[l]
		info2 :: InfoLink = a2.info_link[l]

		# neither agent knows anything
		if info1 == UnknownLink && info2 == UnknownLink
			continue
		end
		
		# both have knowledge at l, compare by trust and transfer accordingly
		if info1 != UnknownLink && info2 != UnknownLink
			frict_cons :: TrustedF = consensus(info1.friction, info2.friction)
			info1.friction = frict_cons
			info2.friction = arr ? average(info2.friction, frict_cons) : frict_cons
			continue
		end

		# only one agent knows the link

		if info1 == UnknownLink
			maybe_learn!(a1, info2)
		else
			maybe_learn!(a2, info1)
		end

		# TODO 
		# - stochasticity
		# - incomplete transfer

	end
end


function step_agent_info!(agent::Agent, model::Model, par)
	for c in agent.contacts
		if rand() < par.p_info_contacts
			exchange_info!(agent, c, model.world, par)
		end
	end
end

