using Util
using Distributions

mutable struct Model
	world :: World
	people :: Vector{Agent}
	migrants :: Vector{Agent}
end


function decide_move(agent :: Agent, world::World, par)
end


function simulate!(model :: Model, steps, par)
	for i in 1:steps
		step_simulation!(model, par)
	end
end


function step_simulation!(model::Model, par)
	handle_departures!(model, par)

	m = 0
	mm = 0
	cap = 0
	targ = 0
	mtarg = 0

	for a in model.migrants
		step_agent!(a, model, par)
		ml = length(a.knowledge)
		m += ml
		mm = max(ml, mm)
		cap += a.capital
		targ += length(a.targets)
		mtarg = max(mtarg, length(a.targets))
	end

	m /= length(model.migrants)
	cap /= length(model.migrants)
	targ /= length(model.migrants)

	println("mem: ", m, " ", mm, " cap: ", cap, " targets: ", targ, " ", mtarg)

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
				receive_info!(agent, l)
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


