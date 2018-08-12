using Util


struct Pos
	x, y :: Int
end

struct Knowledge
	loc :: Pos
	values :: Vector{Float64}
	trust :: Vector{Float64}	
end


const Unknown = Knowledge(Pos(0, 0), [0.0], [0.0])


mutable struct Agent
	loc :: Pos
	knowledge :: Vector{Knowledge}
	capital :: Float64
	contacts
end


# this is very preliminary and should be optimized
function get_knowledge_at(knowledge :: Vector{Knowledge}, x, y)
	for k in knowledge
		if k.loc == Pos(x, y)
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


prop(n::Symbol) = n == :friction ? 0 : (n == :control ? 1 : (n == :information ? 2 : -1))

# named properties
get_p(l :: Location, p :: Symbol) = l.property[prop(n)]
set_p!(l :: Location, p :: Symbol, v :: Float64) = l.property[prop(n) = v]
# resources
get_r(l :: Location, r :: Int) = l.property[i+3]
set_r!(l :: Location, r :: Int, v :: Float64) = l.property[i+3] = v


# construct empty location
function Location()
	Location(Vector{Float64}(10), 0, Vector{Agent}())
end

mutable struct World
	area :: Matrix{Location}
end


remove_agent!(loc::Location, agent::Agent) = drop!(loc.people, agent)


add_agent!(loc::Location, agent::Agent) = push!(loc.people, agent)


find_location(world, x, y) = world.area[x, y]


function move!(world, agent, x, y)
	pos_old = agent.loc
	remove_agent!(world.area[pos_old.x, pos_old.y], agent)
	loc = find_location(world, x, y)
	agent.loc = loc
	add_agent!(loc, agent)
end


