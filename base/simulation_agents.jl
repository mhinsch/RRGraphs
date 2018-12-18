
function costs_stay!(agent, loc, par)
	agent.capital += par.ben_resources * loc.resources - par.costs_stay
end


function costs_move!(agent, loc, par)
	agent.capital -= par.costs_move * loc.friction
end


function plan!(agent, par)
	if agent.targets == []
		agent.plan = []
	else
		agent.plan, count = Pathfinding.path_Astar(knows_current(agent), agent.targets, 
			path_costs, path_costs_estimate, each_neighbour)
	end

	# we have a plan!
	if agent.plan != []
		return agent
	end

	# no plan, try to find better position at least

	loc = knows_current(agent)

	qual = quality(loc)
	best = 0

	for i in each_index(loc.links)
		q = quality(loc.links)
		if q > qual
			qual = q
			best = i
		end
	end

	# can't find a better option, stay
	if best == 0
		return agent
	end

	agent.plan = [other(loc.links[best], loc)]

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


function decide_stay(a, par)
	return a.in_transit || agent.plan == []
end


function step_agent_move!(agent, world, par)
	agent.in_transit = true
	loc = decide_move(agent, world, par)
	if loc == Nowhere
		return
	end

	costs_move!(agent, loc, par)
	explore_move!(agent, world, loc, par)
	move!(world, agent, loc)
end


function step_agent_stay!(agent, world, par)
	agent.in_transit = false
	costs_stay!(agent, agent_location(agent, world), par)
	explore_stay!(agent, world, par)
	mingle!(agent, agent_location(agent, world), par)
	plan!(agent, par)
end


# explore while staying at a location
function explore_stay!(agent, world, par)
	explore_at!(agent, world, agent.loc, 1.0, par)
end

# explore while moving one step
function explore_move!(agent, world, dest, par)
	info_loc2 :: InfoLocation, l = explore_at!(agent, world, dest, 1.0, par)
	info_loc1 :: InfoLocation = knows_current(agent)

	link = get_link(agent.loc, dest)
	# TODO stochastic error
	info = InfoLink(link.id, info_loc1, info_loc2, link.friction, par.trust_travelled)
	learn!(agent, info)
end


function explore_at!(agent, world, loc :: Location, speed, par)
	# knowledge
	info = knows(agent, loc)
	
	if info == Unknown
		# agents start off with expected values
		info = InfoLocation(loc.pos, loc.id, par.res_exp, par.qual_exp, 0.0, 0.0, [], [])
		learn!(agent, info)
	end

	# gain information on local properties
	# stochasticity?
	info.resources += (loc.resources - info.resources) * speed
	info.trust_res += (1.0 - info.trust_res) * speed

	info.quality += (loc.quality - info.quality) * speed
	info.trust_qual += (1.0 - info.trust_qual) * speed

	for link in loc.links
		info_link = knows(agent, link)

		if info_link == UnknownLink && rand() par.p_find_links
			info_to = knows(agent, (link.l1 == loc ? link.l2 : link.l1))
			info_link = InfoLink(link.id, info, info_to, links.friction, par.trust_found_links)
			learn!(agent, info_link)
		end
	end

	info, loc
end


# TODO parameterize
# meet other agents, gain contacts and information
function mingle!(agent, location, par)
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
			exchange_info!(agent, a, par)
		end
	end
end

function transfer(val1, trust1, val2, trust2)
	val1 = (val1 * trust1 + val2 * trust2) / (trust1 + trust2)
	val2 = val1
	trust1 = trust2 = max(trust1, trust2)

	val1, trust1, val2, trust2
end


function exchange_info!(a1, a2, par)

	for l in each_index(a1.info_loc)
		
		info1 = a1.info_loc[l]
		info2 = a2.info_loc[l]

		# neither agent knows anything
		if info1 == Unknown && info2 == Unknown
			continue
		end
		
		# both have knowledge at l, compare by trust and transfer accordingly
		if info1 != Unknown && info2 != Unknown
			@update! transfer info1.resources info1.trust_res info2.resources info2.trust_res
			@update! quality info1.trust_qual info2.quality info2.trust_qual
			continue
		end

		if info2 == Unknown 
			maybe_learn!(a2, a1.info_loc[l], par)
		else # info1 == Unknown
			maybe_learn!(a1, a2.info_loc[l], par)
		end
	end

	for l in each_index(a1.info_link)
		
		info1 = a1.info_link[l]
		info2 = a2.info_link[l]

		# neither agent knows anything
		if info1 == Unknown && info2 == Unknown
			continue
		end
		
		# both have knowledge at l, compare by trust and transfer accordingly
		if info1 != Unknown && info2 != Unknown
			@update! transfer info1.friction, info1.trust, info2.friction, info2.trust 
			continue
		end

		if info2 == Unknown 
			maybe_learn!(a2, a1.info_link[l], par)
		else # info1 == Unknown
			maybe_learn!(a1, a2.info_link[l], par)
		end
	end
end


function step_agent_info!(agent, model, par)
	for c in agent.contacts
		if rand() < par.p_info_contacts
			exchange_info!(agent, c, par)
		end
	end
end

