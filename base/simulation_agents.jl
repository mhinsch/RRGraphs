
include("world_util.jl")

function costs_stay!(agent, loc :: Location, par)
	agent.capital += par.ben_resources * loc.resources - par.costs_stay
end


function costs_move!(agent, link :: Link, par)
	agent.capital -= par.costs_move * link.friction
end


function step_agent!(agent::Agent, model::Model, par)
	if decide_stay(agent, par)
		step_agent_stay!(agent, model.world, par)
	else
		step_agent_move!(agent, model.world, par)
	end

	step_agent_info!(agent, model, par)
end


function step_agent_move!(agent, world, par)
	agent.in_transit = true

	loc = decide_move(agent, world, par)

	link = find_link(agent.loc, loc)
	# update traffic counter
	link.count += 1

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


# *********
# decisions
# *********


function quality(link :: InfoLink, loc :: InfoLocation, par)
	@assert known(link)
	@assert known(loc)
	@assert friction(link) >= 0
	@assert !isnan(friction(link))
	# [0:3]					     [0:1.5]	
	quality(loc, par) / (1.0 + friction(link)*par.qual_weight_frict)
end

function quality(loc :: InfoLocation, par)
	# [0:1]
	discounted(loc.quality) + 
		# [0:1]
		loc.pos.x * par.qual_weight_x + 
		# [0:1]
		discounted(loc.resources) * par.qual_weight_res
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


function costs_quality(l1::InfoLocation, l2::InfoLocation, par)
	link = find_link(l1, l2)
	qual = quality(l2, par)

	friction(link) * (par.path_weight_frict + 3.0) / (par.path_weight_frict + qual)
end


function plan!(agent, par)

	if agent.info_target == []
		agent.plan = []
	else
		if par.path_use_quality
			agent.plan, count = Pathfinding.path_Astar(info_current(agent), agent.info_target, 
			(l1, l2)->costs_quality(l1, l2, par), path_costs_estimate, each_neighbour)
		else
			agent.plan, count = Pathfinding.path_Astar(info_current(agent), agent.info_target, 
				path_costs, path_costs_estimate, each_neighbour)
		end
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

	best = 0
	if quals[end] > 0
		r = rand() * (quals[end] - 0.0001)
		# -1 because first el is stay
		best = findfirst(x -> x>r, quals) - 1
	end

	# either stay or use planned path
	if best == 0 ||
		(best == length(quals) - 1 && agent.plan != [])
		return agent
	end

	# go to best neighbouring location 
	agent.plan = [otherside(loc.links[best], loc), loc]

	agent
end


function decide_stay(agent, par)
	return agent.in_transit || agent.plan == []
end


function decide_move(agent::Agent, world::World, par)
	# end is current location
	world.cities[agent.plan[end-1].id]
end


# ***********
# exploration
# ***********


# explore while staying at a location
function explore_stay!(agent, world, par)
	explore_at!(agent, world, agent.loc, par.speed_expl_stay, true, par)
end

# explore while moving one step
function explore_move!(agent, world, dest, par)
	info_loc2 :: InfoLocation, l = explore_at!(agent, world, dest, par.speed_expl_move, false, par)
	info_loc1 :: InfoLocation = info_current(agent)

	link = find_link(agent.loc, dest)
	inf = info(agent, link)
	if !known(inf)
		# TODO stochastic error
		inf = discover!(agent, link, agent.loc, par)
	end

	inf.friction = TrustedF(link.friction, par.trust_travelled)

	agent
end


# connect loc and link (if not already connected)
function connect!(loc :: InfoLocation, link :: InfoLink)
	# add location to link
	if link.l1 != loc && link.l2 != loc
		# link not connected yet, should have free slot
		if !known(link.l1)
			link.l1 = loc
		elseif !known(link.l2)
			link.l2 = loc
		else
			error("Error: Trying to connect a fully connected link!")
		end
	end

	# add link to location
	if ! (link in loc.links)
		add_link!(loc, link)
	end
end


# add new location to agent (based on world info)
# connect to existing links
function discover!(agent, loc :: Location, par)
	# agents start off with expected values
	inf = InfoLocation(loc.pos, loc.id, TrustedF(par.res_exp), TrustedF(par.qual_exp), [])
	# add location info to agent
	add_info!(agent, inf, loc.typ)
	# connect existing link infos
	for link in loc.links
		info_link = info(agent, link)

		# links to exit are always known
		if !known(info_link)
			if loc.typ != EXIT
				lo = otherside(link, loc)
				if lo.typ == EXIT && knows(agent, lo)
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
	@assert known(info_from)
	info_to = info(agent, otherside(link, from))
	frict = link.distance * par.frict_exp[Int(link.typ)]
	info_link = InfoLink(link.id, info_from, info_to, TrustedF(frict))
	add_info!(agent, info_link)
	# TODO lots of redundancy, possibly join/extend
	connect!(info_from, info_link)
	if known(info_to)
		connect!(info_to, info_link)
	end

	info_link	
end


function explore_at!(agent, world, loc :: Location, speed, allow_indirect, par)
	# knowledge
	inf = info(agent, loc)
	
	if !known(inf)
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

		if !known(info_link) && rand() < par.p_find_links
			info_link = discover!(agent, link, loc, par)

			# TODO imperfect knowledge

			info_link.friction = TrustedF(link.friction, par.trust_found_links)
			
			# no info, but position is known
			explore_at!(agent, world, otherside(link, loc), 0.0, false, par)
		end

		# we might get info on connected location
		if known(info_link) && rand() < par.p_find_dests
			explore_at!(agent, world, otherside(link, loc), 0.5, false, par)
		end
	end

	inf, loc
end


# ********************
# information exchange
# ********************


# add new link as a copy from existing one (from other agent)
# currently requires that both endpoints are known
function maybe_learn!(agent, link_orig :: InfoLink)
	# get corresponding loc info from naive individual
	l1_info = agent.info_loc[link_orig.l1.id] 
	l2_info = agent.info_loc[link_orig.l2.id] 

	# check if the agent knows both end points, otherwise abort
	if !known(l1_info) || !known(l2_info)
		return UnknownLink	
	end

	info_link = InfoLink(link_orig.id, l1_info, l2_info, link_orig.friction)
	add_info!(agent, info_link)
	connect!(l1_info, info_link)
	connect!(l2_info, info_link)

	info_link
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


function exchange_beliefs(val1::TrustedF, val2::TrustedF, par, w1 = 1.0, w2 = 1.0)
	if val1.trust == 0.0 && val2.trust == 0.0
		return val1, val2
	end

	ci1 = par.convince^(1.0/w2)
	ce1 = par.convert^(1.0/w2)
	cu1 = par.confuse

	ci1 = par.convince^(1.0/w1)
	ce1 = par.convert^(1.0/w1)
	cu1 = par.confuse

	t1 = val1.trust		# trust
	d1 = 1.0 - t1		# doubt
	v1 = val1.value

	t2_pcv = sigmoid(rand(), par.error, val2.trust)
	d2_pcv = 1.0 - t2_pcv
	v2_pcv = val2.value * (sigmoid(rand(), par.error, 0.5) + 0.5)
	
	dist1_pcv = abs(v1-v2_pcv) / (v1 + v2_pcv + 0.00001)

	# sum up values according to area of overlap between 1 and 2
	# from point of view of 1:
	# doubt1 x doubt2 -> doubt
	# trust1 x doubt2 -> trust1
	# doubt1 x trust2 -> doubt1 / convince
	# trust1 x trust2 -> trust1 / convert / confuse (doubt)

	#					doubt1 x doubt2		doubt1 x trust2
	d1_ = 					d1 * d2_pcv + 	d1 * t2_pcv * (1.0 - ci1) + 
	#	trust1 x trust2
		t1 * t2_pcv * cu1 * dist1_pcv
	#	trust1 x doubt2
	v1_ = t1 * d2_pcv * v1 + 					d1 * t2_pcv * ci1 * v2_pcv + 
		t1 * t2_pcv * (1.0 - cu1 * dist1_pcv) * ((1.0 - ce1) * v1 + ce1 * v2_pcv)

	t2 = val2.trust
	d2 = 1.0 - t2
	v2 = val2.value

	t1_pcv = sigmoid(rand(), par.error, t1)
	d1_pcv = 1.0 - t1_pcv
	v1_pcv = val1.value * (sigmoid(rand(), par.error, 0.5) + 0.5)

	dist2_pcv = abs(v2-v1_pcv) / (v2 + v1_pcv + 0.00001)

	#					doubt2 x doubt1		doubt2 x trust1
	d2_ = 					d2 * d1_pcv + 	d2 * t1_pcv * (1.0 - ci) + 
	#	trust2 x trust1
		t2 * t1_pcv * cu2 * dist2_pcv
	#	trust2 x doubt1
	v2_ = t2 * d1_pcv * v2 + 					d2 * t1_pcv * ci2 * v1_pcv + 
		t2 * t1_pcv * (1.0 - cu2 * dist2_pcv) * ((1.0 - ce2) * v2 + ce2 * v1_pcv)

	TrustedF(v1_ / (1.0-d1_), 1.0 - d1_), TrustedF(v2_ / (1.0-d2_), 1.0 - d2_)
end


function exchange_info!(a1::Agent, a2::Agent, world::World, par)
	# a1 can never have arrived yet
	arr = arrived(a2)

	for l in eachindex(a1.info_loc)
		if rand() > par.p_transfer_info
			continue
		end
		
		info1 :: InfoLocation = a1.info_loc[l]
		info2 :: InfoLocation = a2.info_loc[l]

		# neither agent knows anything
		if !known(info1) && !known(info2)
			continue
		end
		
		loc = world.cities[l]

		if !known(info1)
			discover!(a1, loc, par)
		elseif !known(info2) && !arr
			discover!(a2, loc, par)
		end

		# both have knowledge at l, compare by trust and transfer accordingly
		if known(info1) && known(info2)
			res1, res2 = exchange_beliefs(info1.resources, info2.resources, par, 1.0, 
				arr ? par.weight_arr : 1.0)
			qual1, qual2 = exchange_beliefs(info1.quality, info2.quality, par, 1.0, 
				arr ? par.weight_arr : 1.0)
			info1.resources = res1
			info1.quality = qual1
			# only a2 can have arrived
			if !arr 
				info2.resources = res2
				info2.quality = qual2
			end
		end
	end

	for l in eachindex(a1.info_link)
		if rand() > par.p_transfer_info
			continue
		end
		
		info1 :: InfoLink = a1.info_link[l]
		info2 :: InfoLink = a2.info_link[l]

		# neither agent knows anything
		if !known(info1) && !known(info2)
			continue
		end

		link = world.links[l]
		
		# only one agent knows the link
		if !known(info1)
			if knows(a1, link.l1) && knows(a1, link.l2)
				discover!(a1, link, link.l1, par)
			end
		elseif !known(info2) && !arr
			if knows(a2, link.l1) && knows(a2, link.l2)
				discover!(a2, link, link.l1, par)
			end
		end
		
		# both have knowledge at l, compare by trust and transfer accordingly
		if known(info1) && known(info2)
			frict1, frict2 = exchange_beliefs(info1.friction, info2.friction, par, 
				arr ? par.weight_arr : 1.0)
			info1.friction = frict1
			if !arr
				info2.friction = frict2
			end
		end
	end
end


function step_agent_info!(agent::Agent, model::Model, par)
	for c in agent.contacts
		if rand() < par.p_info_contacts
			exchange_info!(agent, c, model.world, par)
		end
	end
end

