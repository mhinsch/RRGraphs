using Util


# simple grid coords for now
struct Pos
	x :: Int
	y :: Int
end

# a piece of knowledge an agent has about a location
mutable struct Knowledge
	# where
	loc :: Pos
	# property values the agent expects
	values :: Vector{Float64}
	# how certain it thinks they are
	trust :: Vector{Float64}
	# actual knowledge about a location 
	# (counteracts opaqueness)
	experience :: Float64
end


const Unknown = Knowledge(Pos(0, 0), [], [], 0.0)


# migrants
mutable struct Agent
	# current position
	loc :: Pos
	# what it thinks it knows about the world
	# TODO optimize data structure for access by location
	#knowledge :: Vector{Knowledge}
	knowledge :: Dict{Tuple{Int, Int}, Knowledge}
	# abstract capital, includes time & money
	capital :: Float64
	# people at home & in target country, other migrants
	contacts :: Vector{Agent}
end


Agent(l :: Pos, c :: Float64) = Agent(l, Dict(), c, Agent[])


function add_to_contacts!(agent, a)
	if a in agent.contacts
		return
	end

	push!(agent.contacts, a)
end


# this is very preliminary and should be optimized
# TODO check if it's ok that this returns a reference
function get_knowledge_at(knowledge :: Vector{Knowledge}, x, y)
	for k in knowledge
		if k.loc == Pos(x, y)
			return k
		end
	end

	return Unknown 
end

# this is very preliminary and should be optimized
# TODO check if it's ok that this returns a reference
function get_knowledge_at(knowledge :: Dict{Tuple{Int, Int}, Knowledge}, x, y)
	get(knowledge, (x,y), Unknown)
end


knows_at(agent :: Agent, x, y) = get_knowledge_at(agent.knowledge, x, y)
knows_here(agent :: Agent) = knows_at(agent, agent.loc.x, agent.loc.y)


add_to_knowledge!(k :: Vector{Knowledge}, item) = push!(k, item)
add_to_knowledge!(k :: Dict{Tuple{Int, Int}, Knowledge}, item) = k[(item.loc.x, item.loc.y)] = item

learn!(agent, k) = add_to_knowledge!(agent.knowledge, k)


# one grid point for now (could be node on a graph)
mutable struct Location
	# friction, control, information, resource_1, resource_2, ..., resource_n
	properties :: Vector{Float64}
	# how difficult it is to access resources
	opaqueness :: Float64
	# migrants present
	people :: Vector{Agent}
end


# helper to access properties by name
prop(n::Symbol) = n == :friction ? 1 : (n == :control ? 2 : (n == :information ? 3 : 0))

# named properties
get_p(l :: Location, p :: Symbol) = l.properties[prop(p)]
set_p!(l :: Location, p :: Symbol, v :: Float64) = l.properties[prop(p)] = v
# resources
get_r(l :: Location, r :: Int) = l.properties[i+3]
set_r!(l :: Location, r :: Int, v :: Float64) = l.properties[i+3] = v


# construct empty location
Location() = Location(fill(0.0, 3), 0, Vector{Agent}(undef, 0))

Location(n) = Location(fill(0.0, n+3), 0, Vector{Agent}(undef, 0))


mutable struct World
	area :: Matrix{Location}
	cities :: Vector{Tuple{Int, Int}}
	links :: Vector{Tuple{Int, Int}}
	entries :: Vector{Int}
end

World(x::Int, y::Int) = World(Matrix{Location}(x, y), [], [], [])

World(a::Matrix{Location}) = World(a, [], [], [])


remove_agent!(loc::Location, agent::Agent) = drop!(loc.people, agent)


add_agent!(loc::Location, agent::Agent) = push!(loc.people, agent)


find_location(world, x, y) = world.area[x, y]


agent_location(agent, world) = find_location(world, agent.loc.x, agent.loc.y)


function remove_agent!(world, agent)
	pos = agent.loc
	remove_agent!(world.area[pos.x, pos.y], agent)
end


function move!(world, agent, x, y)
	remove_agent!(world, agent)
	agent.loc = Pos(x, y)
	loc = find_location(world, x, y)
	add_agent!(loc, agent)
end


