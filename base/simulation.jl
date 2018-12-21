using Util
using Distributions

mutable struct Model
	world :: World
	people :: Vector{Agent}
	migrants :: Vector{Agent}
end


function simulate!(model :: Model, steps, par)
	for i in 1:steps
		step_simulation!(model, par)
	end
end


function step_simulation!(model::Model, par)
	handle_departures!(model, par)

	cap = 0
	targ = 0
	mtarg = 0
	plan = 0
	mplan = 0

	println()
	i = 1
	for a in model.migrants
		println("agent ", i, ": ")
		step_agent!(a, model, par)
		i += 1
		cap += a.capital
		targ += length(a.info_target)
		mtarg = max(mtarg, length(a.info_target))
		plan += length(a.plan)
		mplan = max(mplan, length(a.plan))
	end

	cap /= length(model.migrants)
	targ /= length(model.migrants)
	plan /= length(model.migrants)

	println(" cap: ", cap, " targets: ", targ, " ", mtarg, " plan: ", plan, " ", mplan)

	handle_arrivals!(model, par)
end


# *** entry/exit


function handle_departures!(model::Model, par)
	p_dist = Poisson(par.rate_dep)
	n = rand(p_dist)
	for i in 1:n
		x = 1
		entry = rand(model.world.entries)
		# starts as in transit => will explore in first step
		agent = Agent(entry, par.ini_capital)
		agent.info_loc = fill(Unknown, length(model.world.cities))
		agent.info_link = fill(UnknownLink, length(model.world.links))
		add_agent!(entry, agent)
		push!(model.people, agent)
		push!(model.migrants, agent)

		# add initial contacts
		# (might have duplicates)
		nc = min(length(model.people) ÷ 10, par.n_ini_contacts)
		for c in 1:nc
			push!(agent.contacts, model.people[rand(1:length(model.people))])
		end

		# some exits are known
		# the only bit of initial global info so far
		for l in model.world.exits
			if rand() < par.p_know_target
				explore_at!(agent, model.world, l, 0.5, false, par)
			end
		end
	end
end


# all agents at target get removed from world (but remain in network)
function handle_arrivals!(model::Model, par)
	for i in length(model.migrants):-1:1
		if model.migrants[i].loc in model.world.exits
			agent = model.migrants[i]
			drop_at!(model.migrants, i)
			remove_agent!(world, agent)
		end
	end
end

include("simulation_agents.jl")
