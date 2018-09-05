include("world.jl")


mutable struct Model
	world :: World
	people :: Vector{Agent}
	migrants :: Vector{Agent}
	network
	knowledge
end


# TODO include
# - effects of certainty vs. attractiveness
# - location (i.e. closer to target)
# - plans (?)
# - transport (?)
function quality(k :: Knowledge)
	1.0
end


# currently very simplistically selects the von Neumann neighbour with the
# highest quality
# TODO include transport?
# TODO include plans?
function decide_move(agent :: Agent)
	loc = agent.loc
	# von Neumann neighbourhood
	candidates = [knows_at(agent, loc.x, loc.y-1), 
		knows_at(agent, loc.x, loc.y+1),
		knows_at(agent, loc.x-1, loc.y),
		knows_at(agent, loc.x+1, loc.y)]

	# find best neighbour
	best = 0.0
	l = 0
	for c in eachindex(candidates)
		q = quality(candidates[c])
		if q > best
			best = q
			l = c
		end
	end

	# if there's a best neighbour, go there
	if l > 0
		return candidates[l].loc
	else
		return Pos(0, 0)
	end
end


function simulate!(model :: Model, steps)
	for in in 1:steps
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


function step_agent!(agent :: Agent, model::Model)
	if decide_stay(agent)
		step_agent_stay!(agent, model.world)
	else
		step_agent_move!(agent, model.world)
	end

	step_agent_info!(agent, model)
end


function step_agent_move!(agent, world)
	loc_old = agent.loc
	loc = decide_move(agent)
	costs_move!(agent, loc)
	move!(world, agent, loc.x, loc.y)
end


function step_agent_stay!(agent, world)
	costs_stay!(agent)
	explore!(agent)
	mingle!(agent)
	learn!(agent)
end


# TODO 
function explore!(agent)
end





# TODO spread info to other agent/public
# - local agents
# 	- all combis or hub and spokes?
# - social network
# - public information
function step_agent_info!(agent, model)
end


# *** entry/exit


# TODO regularly add new agents
# - need to be inserted at rand loc at origin
# - fixed rate over time?
function handle_departures!(model::World)
end


# TODO remove arrived agents
# - all agents at target get removed from world
# - *but* remain in network!
function handle_arrivals!(model::World)
end


