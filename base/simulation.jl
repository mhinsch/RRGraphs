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
function quality(k :: Knowledge, par)
	if (k.loc == Pos(0, 0))
		return rand() * 0.1
	end

	v = k.loc.x/2000
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
	candidates = Tuple{Knowledge, Pos}[]
	x1 = max(loc.x-1, 1)
	x2 = min(loc.x+1, size(world.area)[1])
	y1 = max(loc.y-1, 1)
	y2 = min(loc.y+1, size(world.area)[2])

	bestx, besty = 0, 0
	bestq = 0.0
	for x in x1:x2, y in y1:y2
		q = quality(knows_at(agent, x, y), par)
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

	for a in model.migrants
		step_agent!(a, model, par)
	end

	handle_arrivals!(model, par)

	spread_information!(model, par)
end


function spread_information!(model::Model, par)
	# needed?
end


# *** agent simulation


function costs_stay!(a, par)
end


function costs_move!(a, pos, par)
end


function step_agent!(agent :: Agent, model::Model, par)
	if decide_stay(agent, par)
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
	loc_old = agent.loc
	loc = decide_move(agent, world, par)
	if loc == Pos(0, 0)
		return
	end

	#println("moving to $(loc.x), $(loc.y)")
	costs_move!(agent, loc, par)
	move!(world, agent, loc.x, loc.y)
end


function step_agent_stay!(agent, world, par)
	costs_stay!(agent, par)
	explore!(agent, world, par)
	mingle!(agent, agent_location(agent, world), par)
end


# arbitrary, very simplistic implementation
# TODO discuss with group
# TODO parameterize
function explore!(agent, world, par)
	# knowledge
	k = knows_here(agent)
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
		
		exchange_info!(agent, a, par)
	end
end


# TODO imperfect exchange (e.g. skip random knowledge pieces)
# TODO exchange dependent on trust into source
function exchange_info!(a1, a2, par)
	for k in a1.knowledge
		l = k.loc
		k_other = knows_at(a2, l.x, l.y)
		
		# *** only a1 knows the location

		if k_other == Unknown
			# TODO full transfer of experience?
			learn!(a2, k)
			continue
		end

		# *** both know the location

		# TODO full transfer?
		@set_to_max!(k.experience, k.other_experience)

		# both have knowledge at l, compare by trust and transfer accordingly
		for i in eachindex(k.values)
			if k.trust[i] > k_other.trust[i]
				k_other.value[i] = k.value[i]
				k_other.trust[i] = k.value[i]
			else
				k.value[i] = k_other.value[i]
				k.trust[i] = k_other.value[i]
			end
		end
	end

	# *** transfer for location a2 knows but a1 doesn't
	
	for k in a2.knowledge
		l = k.loc
		k_other = knows_at(a1, l.x, l.y)
		
		# other has no knowledge at this location, just add it
		if k_other == Unknown
			# TODO full transfer of experience?
			learn!(a2, k)
			continue
		end
	end
end


# TODO spread info to other agent/public
# - social network
# - public information
function step_agent_info!(agent, model, par)
end


# *** entry/exit


# TODO fixed rate over time?
# TODO initial contacts
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


