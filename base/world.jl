include("util.jl")


struct Knowledge
	loc :: Tuple{Int, Int}
	values :: Vector{Float64}
	trust :: Vector{Float64}	
end


const Unknown = Knowledge((0, 0), [0.0], [0.0])


mutable struct Agent
	loc :: Tuple{Int, Int}
	knowledge :: Vector{Knowledge}
	capital :: Float64
	contacts
end


# this is very preliminary and should be optimized
function get_knowledge_at(knowledge :: Vector{Knowledge}, x, y)
	for k in knowledge
		if k.loc == (x, y)
			return k
		end
	end

	return Unknown 
end


knows_at(agent :: Agent, x, y) = get_knowledge_at(agent.knowledge, x, y)


struct Location
	# friction, control, information, resource1, resource2, ...
	properties :: Vector{Float64}
	opaqueness :: Float64
	people :: Vector{Agent}
end


mutable struct World
	area :: Matrix{Location}
end


remove_agent!(loc::Location, agent::Agent) = drop!(loc.people, agent)


add_agent!(loc::Location, agent::Agent) = push!(loc.people, agent)


find_location(world, x, y) = world.area[x, y]


function move!(world, agent, x, y)
	xold, yold = agent.loc
	remove_agent!(world.area[xold, yold], agent)
	loc = find_location(world, x, y)
	agent.loc = loc
	add_agent!(loc, agent)
end


function decide_move(agent :: Agent)
	
end
