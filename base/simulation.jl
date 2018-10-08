using  Util

mutable struct Model
	world :: World
	people :: Vector{Agent}
	migrants :: Vector{Agent}
#	network
#knowledge
end


# TODO include
# - effects of certainty vs. attractiveness
# - plans (?)
# - transport (?)
# - local experience (?)
function quality(x, y, dx, k :: Knowledge, par)
	v = 2.0 + dx
	if (k == Unknown)
		return v + (rand() < 0.1 ? rand() : rand() * 0.1)
	end

	v += (1.0 - k.values[1]) * par.weight_friction
	v += (1.0 - k.values[2]) * par.weight_control
	v += k.values[3] * par.weight_info

	for i in 4:length(k.values)
		v += k.values[i] * par.weight_resources / i
	end
	
	v
end


# currently very simplistically selects the von Neumann neighbour with the
# highest quality
# TODO include transport?
# TODO include plans?
function decide_move(agent :: Agent, world::World, par)
	loc = agent.loc
	# Moore neighbourhood
	x1 = max(loc.x-1, 1)
	x2 = min(loc.x+1, size(world.area)[1])
	y1 = max(loc.y-1, 1)
	y2 = min(loc.y+1, size(world.area)[2])

	bestx, besty = 0, 0
	bestq = 0.0
	for x in x1:x2, y in y1:y2
		q = quality(x, y, x-loc.x, knows_at(agent, x, y), par)
		if q > bestq
			bestq = q
			bestx, besty = x, y
		end
	end

	# if there's a best neighbour, go there
	if bestx > 0
		return Pos(bestx, besty)
	else
		return Pos(0, 0)
	end
end


function simulate!(model :: Model, steps, par)
	for i in 1:steps
		step_simulation!(model, par)
	end
end


function step_simulation!(model::Model, par)
	handle_departures!(model, par)

	m = 0

	for a in model.migrants
		step_agent!(a, model, par)
		m += length(a.knowledge)
	end

	m /= length(model.migrants)

	println("avg. mem: ", m)

	handle_arrivals!(model, par)

	spread_information!(model, par)
end


function spread_information!(model::Model, par)
	# needed?
end


# *** agent simulation


# TODO opaqueness/experience
function costs_stay!(a, loc, par)
	a.capital -= par.costs_stay
	for i in 4:length(loc.properties)
		a.capital += par.ben_resources * loc.properties[i] / i
	end
end


# TODO control
function costs_move!(a, loc, par)
	a.capital -= par.costs_move * get_p(loc, :friction)
end


function step_agent!(agent :: Agent, model::Model, par)
	if agent.capital < 0.0 || decide_stay(agent, par)
		step_agent_stay!(agent, model.world, par)
	else
		step_agent_move!(agent, model.world, par)
	end

	step_agent_info!(agent, model, par)
end


# TODO put some real logic here
function decide_stay(a, par)
	return rand() > 0.5
end


function step_agent_move!(agent, world, par)
	loc = decide_move(agent, world, par)
	if loc == Pos(0, 0)
		return
	end

	#println("moving to $(loc.x), $(loc.y)")
	costs_move!(agent, find_location(world, loc.x, loc.y), par)
	move!(world, agent, loc.x, loc.y)
end


function step_agent_stay!(agent, world, par)
	costs_stay!(agent, agent_location(agent, world), par)
	explore!(agent, world, par)
	mingle!(agent, agent_location(agent, world), par)
end


# arbitrary, very simplistic implementation
# TODO discuss with group
# TODO parameterize
function explore!(agent, world, par)
	# knowledge
	k = knows_here(agent)
	
	if k == Unknown
		k = Knowledge(fill(0.0, par.n_resources + 3), fill(0.0, par.n_resources+3), 0.0)
		learn!(agent, k, agent.loc.x, agent.loc.y)
	end

	# location
	l = agent_location(agent, world)

	# gain local experience
	k.experience += (1.0 - k.experience) * (1.0 - l.opaqueness)

	# gain information on local properties
	for p in eachindex(k.values)
		# stochasticity?
		k.values[p] += (l.properties[p] - k.values[p]) * k.experience
		k.trust[p] += (1.0 - k.trust[p]) * k.experience
	end
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

function interesting(agent, knowl, x, y, par)
	boring = true
	for t in knowl.trust
		if t > par.boring
			boring = false
			break;
		end
	end
	if boring
		return false
	end

	if abs(agent.loc.y - y) > par.too_far
		return false
	end

	return true
end

# TODO exchange dependent on trust into source
function exchange_info!(a1, a2, par)
	for (loc, k) in a1.knowledge

		@assert k != Unknown

		l = Pos(loc[1], loc[2])
		k_other = knows_at(a2, l.x, l.y)
		
		# *** only a1 knows the location

		if k_other == Unknown 
			if interesting(a2, k, l.x, l.y, par) && rand() < par.p_transfer_info && 
					length(a2.knowledge) < par.max_mem
				learn!(a2, Knowledge(k), l.x, l.y)
			end
			continue
		end

		# *** both know the location

		# TODO full transfer?
		k.experience = k_other.experience = max(k.experience, k_other.experience)

		# both have knowledge at l, compare by trust and transfer accordingly
		for i in eachindex(k.values)
			if k.trust[i] > k_other.trust[i]
				k_other.values[i] = k.values[i]
				k_other.trust[i] = k.trust[i]
			else
				k.values[i] = k_other.values[i]
				k.trust[i] = k_other.trust[i]
			end
		end
	end

	# *** transfer for location a2 knows but a1 doesn't
	
	for (loc, k) in a2.knowledge
		l = Pos(loc[1], loc[2])
		k_other = knows_at(a1, l.x, l.y)
		
		# other has no knowledge at this location, just add it
		if k_other == Unknown 
			#	println(length(a1.knowledge))
			if interesting(a1, k, l.x, l.y, par) && rand() < par.p_transfer_info &&
					length(a1.knowledge) < par.max_mem
				learn!(a1, Knowledge(k), l.x, l.y)
			end
			continue
		end
	end
end


# TODO spread info to other agent/public
# - social network
# - public information
function step_agent_info!(agent, model, par)
	for c in agent.contacts
		if rand() < par.p_info_contacts
			exchange_info!(agent, c, par)
		end
	end
end


# *** entry/exit


# TODO fixed rate over time?
# TODO initial knowledge
function handle_departures!(model::Model, par)
	for i in 1:par.n_dep_per_step
		x = 1
		entry = rand(1:length(model.world.entries))
		y = model.world.entries[entry] + rand(-5:5)
		a = Agent(Pos(x, y), par.ini_capital)
		l = find_location(model.world, x, y)
		add_agent!(l, a)
		push!(model.people, a)
		push!(model.migrants, a)

		# add initial contacts
		# TODO remove duplicates
		nc = min(length(model.people) ÷ 10, par.n_ini_contacts)
		for c in 1:nc
			push!(a.contacts, model.people[rand(1:length(model.people))])
		end

	end
end


# all agents at target get removed from world (but remain in network)
function handle_arrivals!(model::Model, par)
	# go backwards, so that removal doesn't mess up the index
	for i in length(model.migrants):1
		if model.migrants[i].loc.x >= size(model.world.area)[1]
			drop_at!(model.migrants, i)
			remove_agent!(world, agent)
		end
	end
end


