include("world.jl")


mutable struct Model
	world :: World
	people :: Vector{Agent}
	migrants :: Vector{Agent}
	network
	knowledge
end

# TODO
function quality(k :: Knowledge)
	1.0
end


function decide_move(agent :: Agent)
	loc = agent.loc
	candidates = [knows_at(agent, loc.x, loc.y-1), 
		knows_at(agent, loc.x, loc.y+1),
		knows_at(agent, loc.x-1, loc.y),
		knows_at(agent, loc.x+1, loc.y)]

	best = 0.0
	l = 0
	for c in eachindex(candidates)
		q = quality(candidates[c])
		if q > best
			best = q
			l = c
		end
	end

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
	move!(world, agent, loc...)
end


function step_agent_stay!(agent, world)
	costs_stay!(agent)
	explore!(agent)
	mingle!(agent)
	learn!(agent)
end


function step_agent_info!(agent, model)
# TODO spread info to other agent/public
end


# *** entry/exit


function handle_departures!(model::World)
# TODO regularly add new agents
end


function handle_arrivals!(model::World)
# TODO remove arrived agents
end


include("init.jl")
