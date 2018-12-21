
include("world_util.jl")

function costs_stay!(agent, loc :: Location, par)
	agent.capital += par.ben_resources * loc.resources - par.costs_stay
end


function costs_move!(agent, link :: Link, par)
	agent.capital -= par.costs_move * link.friction
end


function quality(link :: InfoLink, loc :: InfoLocation, par)
	loc.quality*loc.trust_res + loc.pos.x*par.qual_weight_x + 
		loc.resources*loc.trust_res*par.qual_weight_trust -
		link.friction*par.qual_weight_frict 
end

function quality(loc :: InfoLocation, par)
	loc.quality*loc.trust_res + loc.pos.x*par.qual_weight_x + 
		loc.resources*loc.trust_res*par.qual_weight_trust
end


function plan!(agent, par)
	if agent.info_target == []
		agent.plan = []
	else
		agent.plan, count = Pathfinding.path_Astar(knows_current(agent), agent.info_target, 
			path_costs, path_costs_estimate, each_neighbour)
	end

	qual_plan = 0.0

	# we have a plan!
	if agent.plan != []
		return agent
	end

	# no plan, try to find better position at least

	loc = knows_current(agent)

	qual = quality(loc, par)
	best = 0

	for i in eachindex(loc.links)
		q = quality(loc.links[i], otherside(loc.links[i], loc), par)
		#q = quality(otherside(loc.links[i], loc), par)
		@assert !isnan(q)
		if q > qual
			print(".")
			qual = q
			best = i
		end
	end

	# can't find a better option, stay
	if best == 0
		return agent
	end

	agent.plan = [otherside(loc.links[best], loc), loc]

	agent
end


function step_agent!(agent :: Agent, model::Model, par)
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


function decide_move(agent :: Agent, world::World, par)
	# end is current location
	world.cities[agent.plan[end-1].id]
end


function step_agent_move!(agent, world, par)
	agent.in_transit = true
	print("a : ", agent.loc.id, " p: ") 
	for p in agent.plan
		print(p.id, " ")
	end
	print(" || ")

	loc = decide_move(agent, world, par)

	link = find_link(agent.loc, loc)
	link.count += 1

	println("a: ", agent.loc.id, " -> ", loc.id) 

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
	info_loc1 :: InfoLocation = knows_current(agent)

	link = find_link(agent.loc, dest)
	info = knows(agent, link)
	if info == UnknownLink
		# TODO stochastic error
		info = discover!(agent, link, agent.loc, par)
		info.friction = link.friction
		info.trust = par.trust_travelled
	end
	# TODO adjust friction, trust if link known?

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


# add new location to agent
# connect to existing links
function discover!(agent, loc :: Location, par)
	# agents start off with expected values
	info = InfoLocation(loc.pos, loc.id, par.res_exp, par.qual_exp, 0.0, 0.0, [], [])
	# add location info to agent
	learn!(agent, info, loc.typ)
	# connect existing link infos
	for link in loc.links
		info_link = knows(agent, link)

		# links to exit are always known
		if info_link == UnknownLink
			if loc.typ != EXIT
				lo = otherside(link, loc)
				if lo.typ == EXIT && knows(agent, lo) != Unknown
					discover!(agent, link, loc, par)
				end
			end
		# connect known links
		else				
			connect!(info, info_link)
		end
	end

	info	
end	


# add new link to agent
# connect to existing location
function discover!(agent, link :: Link, from :: Location, par)
	info_from = knows(agent, from)
	@assert info_from != Unknown
	info_to = knows(agent, otherside(link, from))
	info_link = InfoLink(link.id, info_from, info_to, par.frict_exp, 0.0)
	learn!(agent, info_link)
	# TODO lots of redundancy, possibly join/extend
	connect!(info_from, info_link)
	if info_to != Unknown
		connect!(info_to, info_link)
	end

	info_link	
end


function explore_at!(agent, world, loc :: Location, speed, indirect, par)
	# knowledge
	info = knows(agent, loc)
	
	if info == Unknown
		info = discover!(agent, loc, par)
	end

	# gain information on local properties
	# stochasticity?
	info.resources += (loc.resources - info.resources) * speed
	info.trust_res += (1.0 - info.trust_res) * speed

	info.quality += (loc.quality - info.quality) * speed
	info.trust_qual += (1.0 - info.trust_qual) * speed

	# only location, no links
	if ! indirect
		return info, loc
	end
	# gain info on links and linked locations
	
	for link in loc.links
		info_link = knows(agent, link)

		if info_link == UnknownLink && rand() < par.p_find_links
			info_link = discover!(agent, link, loc, par)

			info_link.friction = link.friction
			info_link.trust = par.trust_found_links
			
			# no info, but position is known
			explore_at!(agent, world, otherside(link, loc), 0.0, false, par)
		end

		# we might get info on connected location
		if info_link != Unknown && rand() < par.p_find_dests
			explore_at!(agent, world, otherside(link, loc), 0.5, false, par)
		end
	end

	info, loc
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
			add_to_contacts!(agent, a)
			add_to_contacts!(a, agent)
		end
		
		if rand() < par.p_info_mingle
			exchange_info!(agent, a, world, par)
		end
	end
end

function transfer(val1, trust1, val2, trust2)
	t = max(trust1 + trust2, 0.0001)
	val1 = (val1 * trust1 + val2 * trust2) / t
	val2 = val1
	trust1 = trust2 = max(trust1, trust2)

	val1, trust1, val2, trust2
end


function exchange_info!(a1, a2, world, par)

	for l in eachindex(a1.info_loc)
		
		info1 = a1.info_loc[l]
		info2 = a2.info_loc[l]

		# neither agent knows anything
		if info1 == Unknown && info2 == Unknown
			continue
		end
		
		# both have knowledge at l, compare by trust and transfer accordingly
		if info1 != Unknown && info2 != Unknown
			@update! transfer info1.resources info1.trust_res info2.resources info2.trust_res
			@update! transfer info1.quality info1.trust_qual info2.quality info2.trust_qual
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
		
		info1 = a1.info_link[l]
		info2 = a2.info_link[l]

		# neither agent knows anything
		if info1 == Unknown && info2 == Unknown
			continue
		end
		
		# both have knowledge at l, compare by trust and transfer accordingly
		if info1 != Unknown && info2 != Unknown
			@update! transfer info1.friction info1.trust info2.friction info2.trust 
			continue
		end

		# TODO this is slightly tricky since currently agents aren't supposed to know a link
		# without knowing at least 1 endpoint
		# - stochasticity
		# - incomplete transfer
		#link = world.links[l]
		#if info2 == Unknown 
		#	discover!(a2, link, par)
		#else # info1 == Unknown
		#	discover!(a1, link, par)
		#end
	end
end


function step_agent_info!(agent, model, par)
	for c in agent.contacts
		if rand() < par.p_info_contacts
			exchange_info!(agent, c, model.world, par)
		end
	end
end

