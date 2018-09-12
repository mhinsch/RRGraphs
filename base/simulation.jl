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
# - location (i.e. closer to target)
# - plans (?)
# - transport (?)
function quality(k :: Knowledge)
	k.loc == Pos(0, 0) ? rand() * 0.1 : rand()
end

function valid_location(l :: Pos, world :: World)
	l.x > 0 && l.x <= size(world.area)[1] &&
		l.y > 0 && l.y <= size(world.area)[2]
end


# currently very simplistically selects the von Neumann neighbour with the
# highest quality
# TODO include transport?
# TODO include plans?
function decide_move(agent :: Agent, world::World)
	loc = agent.loc
	# von Neumann neighbourhood
	candidates = Tuple{Knowledge, Pos}[]
	if loc.x > 1 
		push!(candidates, (knows_at(agent, loc.x-1, loc.y), Pos(loc.x-1, loc.y)))
	end
	if loc.x < size(world.area)[1]
		push!(candidates, (knows_at(agent, loc.x+1, loc.y), Pos(loc.x+1, loc.y)))
	end

	if loc.y > 1 
		push!(candidates, (knows_at(agent, loc.x, loc.y-1), Pos(loc.x, loc.y-1)))
	end
	if loc.y < size(world.area)[2]
		push!(candidates, (knows_at(agent, loc.x, loc.y+1), Pos(loc.x, loc.y+1)))
	end
	
	#println("$(size(candidates)) locs")

	# find best neighbour
	best = 0.0
	l = 0
	for c in eachindex(candidates)
	#	println("c: $c")
		q = quality(candidates[c][1])
	#	println("q: $q")
		if q > best
	#		println(">")
			best = q
			l = c
		end
	end

	# if there's a best neighbour, go there
	if l > 0
	#	println("l: $(candidates[l][2])")
		return candidates[l][2]
	else
		return Pos(0, 0)
	end
end


function simulate!(model :: Model, steps)
	for i in 1:steps
		step_simulation!(model)
	end
end


function step_simulation!(model::Model)
	handle_departures!(model)

	for a in model.migrants
		step_agent!(a, model)
	end

	handle_arrivals!(model)

	spread_information!(model)
end


function spread_information!(model::Model)
	# needed?
end


# *** agent simulation


function costs_stay!(a)
end


function costs_move!(a, pos)
end


function step_agent!(agent :: Agent, model::Model)
	if decide_stay(agent)
		step_agent_stay!(agent, model.world)
	else
		step_agent_move!(agent, model.world)
	end

	step_agent_info!(agent, model)
end


# TODO put some real logic here
function decide_stay(a)
	return rand() > 0.5
end


function step_agent_move!(agent, world)
	loc_old = agent.loc
	loc = decide_move(agent, world)
	if loc == Pos(0, 0)
		return
	end

	#println("moving to $(loc.x), $(loc.y)")
	costs_move!(agent, loc)
	move!(world, agent, loc.x, loc.y)
end


function step_agent_stay!(agent, world)
	costs_stay!(agent)
	explore!(agent, world)
	mingle!(agent, agent_location(agent, world))
end


# arbitrary, very simplistic implementation
# TODO discuss with group
# TODO parameterize
function explore!(agent, world)
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
function mingle!(agent, location)
	for a in location.people
		if a == agent
			continue
		end

		# agents keep in contact
		if rand() < 0.3	# arbitrary number
			add_to_contacts!(agent, a)
			add_to_contacts!(a, agent)
		end
		
		exchange_info!(agent, a)
	end
end


# TODO imperfect exchange (e.g. skip random knowledge pieces)
# TODO exchange dependent on trust into source
function exchange_info!(a1, a2)
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
function step_agent_info!(agent, model)
end


# *** entry/exit


# TODO fixed rate over time?
# TODO parameterize
# TODO initial contacts
# TODO initial knowledge
function handle_departures!(model::Model)
	for i in 1:100
		x = 1
		y = rand(1:size(model.world.area)[2])
		a = Agent(Pos(x, y), 100.0)
		l = find_location(model.world, x, y)
		add_agent!(l, a)
		push!(model.people, a)
		push!(model.migrants, a)
	end
end


# all agents at target get removed from world (but remain in network)
function handle_arrivals!(model::Model)
	# go backwards, so that removal doesn't mess up the index
	for i in length(model.migrants):1
		if model.migrants[i].loc.x >= size(model.world.area)[1]
			drop_at!(model.migrants, i)
			remove_agent!(world, agent)
		end
	end
end


