using Util
using Distributions

mutable struct Model
	world :: World
	people :: Vector{Agent}
	migrants :: Vector{Agent}
#	network
#knowledge
end


function quality(agent, k :: Knowledge, boring, par)
	
	v
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
	a.capital -= par.costs_move * get_p(loc, FRICTION)
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
	explore_at!(agent, world, loc.x, loc.y, par.move_learn, par)

	check_targets!(agent)
end


function step_agent_stay!(agent, world, par)
	costs_stay!(agent, agent_location(agent, world), par)
	explore!(agent, world, par)
	mingle!(agent, agent_location(agent, world), par)
end


function explore!(agent, world, par)
	loc = agent.loc
	# Moore neighbourhood
	x1 = max(loc.x-1, 1)
	x2 = min(loc.x+1, size(world.area)[1])
	y1 = max(loc.y-1, 1)
	y2 = min(loc.y+1, size(world.area)[2])

	info = get_p(find_location(world, loc.x, loc.y), INFO)

	for x in x1:x2, y in y1:y2
		if x == loc.x && y == loc.y
			explore_at!(agent, world, x, y, 1.0, par)
		else
			explore_at!(agent, world, x, y, info, par)
		end
	end
end


# arbitrary, very simplistic implementation
# TODO discuss with group
function explore_at!(agent, world, x, y, speed, par)
	# knowledge
	k = knows_at(agent, x, y)
	
	# location
	l = find_location(world, x, y)

	if k == Unknown
		# agents start off with expected values
		k = Knowledge(copy(par.intr_expctd[l.typ, :]), fill(0.0, par.n_resources+3), 0.0)
		# fill remaining resources
		for i in (length(k.values)+1):(par.n_resources+3)
			push!(k.values, par.intr_expctd[l.typ, RESRC])
		end
		learn!(agent, k, agent.loc.x, agent.loc.y)
	end

	# gain local experience
	k.experience += (1.0 - k.experience) * (1.0 - l.opaqueness) * speed

	# gain information on local properties
	for p in eachindex(k.values)
		# stochasticity?
		k.values[p] += (l.properties[p] - k.values[p]) * k.experience * speed
		k.trust[p] += (1.0 - k.trust[p]) * k.experience * speed
	end

	k, l
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

function interesting_coord(agent, x, y, par)
	if abs(agent.loc.y - y) > par.too_far
		return false
	end

	if agent.loc.x - x > par.look_back
		return false
	end

	return true
end


function interesting(agent, knowl, x, y, par)
	int = 0.0	

	for i in eachindex(knowl.trust)
		int = max(int, sqrt(knowl.trust[i]) * 
			valley(knowl.values[i], par.intr_expctd[L_DEFAULT, i], par.intr_steep[i]))
	end

	@assert 0 <= int <= 1

	int
end


function reachable(agent, pos)
	l = agent.loc
	pos.x > l.x && abs(pos.y - l.y) / (pos.x - l.x) < 1.0
end


function check_targets!(agent)
	n = length(agent.targets) 
	if n < 1 || reachable(agent, agent.targets[1])
		return
	end
	
	hole = 1
	for i in 2:n
		if reachable(agent, agent.targets[i])
			agent.targets[hole] = agent.targets[i]
			hole += 1
		end
	end

	deleteat!(agent.targets, hole:n)
end


function maybe_target!(agent, k, x, y, par, check=true)
	pt = Pos(x, y)
	if check && (pt in agent.targets)
		return
	end

	q = quality_target(k, par)

	#print(round(q, digits=2), ",")

	if q < par.min_target_quality
		return
	end

	if !reachable(agent, pt)
		return
	end
	
	push!(agent.targets, pt)
	sort!(agent.targets, by = pos -> pos.x)
end


function maybe_learn!(agent, k, l, par)
	if length(agent.knowledge) >= par.max_mem || rand() >= par.p_transfer_info 
		return
	end

	int = interesting(agent, k, l.x, l.y, par) 
	if (rand()+rand())/2 < int 
		learn!(agent, Knowledge(k), l.x, l.y)
		maybe_target!(agent, k, l.x, l.y, par, false)
	else
		set_boring!(agent, l.x, l.y, int)
	end
end


function exchange_info!(a1, a2, par)
	for (loc, k) in a1.knowledge

		@assert k != Unknown

		l = Pos(loc[1], loc[2])

		# too far away or too far back
		if !interesting_coord(a2, l.x, l.y, par)
			continue
		end

		k_other = knows_at(a2, l.x, l.y)
		
		# *** only a1 knows the location

		if k_other == Unknown 
			maybe_learn!(a2, k, l, par)
			continue
		end

		# *** both know the location

		# TODO full transfer?
		k.experience = k_other.experience = max(k.experience, k_other.experience)

		# both have knowledge at l, compare by trust and transfer accordingly
		for i in eachindex(k.values)
			k.values[i] = (k.values[i] * k.trust[i] + k_other.values[i] * k_other.trust[i]) /
				(k.trust[i] + k_other.trust[i])
			k_other.values[i] = k.values[i]
			k.trust[i] = k_other.trust[i] = max(k.trust[i], k_other.trust[i])
		end

		# maybe this becomes an interesting target now
		maybe_target!(a1, k, l.x, l.y, par)
		maybe_target!(a2, k_other, l.x, l.y, par)
	end

	# *** transfer for location a2 knows but a1 doesn't
	
	for (loc, k) in a2.knowledge
		l = Pos(loc[1], loc[2])

		# too far away or too far back
		if !interesting_coord(a1, l.x, l.y, par)
			continue
		end

		k_other = knows_at(a1, l.x, l.y)
		
		# other has no knowledge at this location, add it
		if k_other == Unknown 
			maybe_learn!(a1, k, l, par)
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
	p = Poisson(par.rate_dep)
	n = rand(p)
	for i in 1:n
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
	for i in length(model.migrants):-1:1
		if model.migrants[i].loc.x >= size(model.world.area)[1]
			agent = model.migrants[i]
			drop_at!(model.migrants, i)
			remove_agent!(world, agent)
		end
	end
end


