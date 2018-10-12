using Util
using Util.PageDict


# simple grid coords for now
struct Pos
	x :: Int
	y :: Int
end

# a piece of knowledge an agent has about a location
mutable struct Knowledge
	# property values the agent expects
	values :: Vector{Float64}
	# how certain it thinks they are
	trust :: Vector{Float64}
	# actual knowledge about a location 
	# (counteracts opaqueness)
	experience :: Float64
end

function Knowledge(k::Knowledge)
	Knowledge(copy(k.values), copy(k.trust), k.experience)
end

const Unknown = Knowledge([], [], 0.0)


# migrants
mutable struct Agent
	# current position
	loc :: Pos
	# what it thinks it knows about the world
	# TODO optimize data structure for access by location
	#knowledge :: Dict{Tuple{Int, Int}, Knowledge}
	knowledge :: Page{Knowledge}
	boring :: Page{Float64}
	# abstract capital, includes time & money
	capital :: Float64
	# people at home & in target country, other migrants
	contacts :: Vector{Agent}
end


#Agent(l :: Pos, c :: Float64) = Agent(l, Dict(), c, Agent[])
Agent(l :: Pos, c :: Float64) = Agent(l, Page{Knowledge}(), Page{Float64}(), c, Agent[])


function add_to_contacts!(agent, a)
	if a in agent.contacts
		return
	end

	push!(agent.contacts, a)
end


# this is very preliminary and should be optimized
# TODO check if it's ok that this returns a reference
get_knowledge_at(k :: Dict{Tuple{Int, Int}, Knowledge}, x, y) = get(k, (x,y), Unknown)
get_knowledge_at(k::Page{Knowledge}, x, y) = get(k, x, y, Unknown)

knows_at(agent :: Agent, x, y) = get_knowledge_at(agent.knowledge, x, y)
knows_here(agent :: Agent) = knows_at(agent, agent.loc.x, agent.loc.y)


add_to_knowledge!(k :: Dict{Tuple{Int, Int}, Knowledge}, item, x, y) = k[(x, y)] = item
add_to_knowledge!(k :: Page{Knowledge}, item, x, y) = set!(k, item, x, y)

learn!(agent, k, x, y) = add_to_knowledge!(agent.knowledge, k, x, y)

set_boring!(agent, x, y, v) = set!(agent.boring, v, x, y)
is_boring(agent, x, y) = get(agent.boring, x, y, NaN)


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
get_r(l :: Location, r :: Int) = l.properties[r+3]
set_r!(l :: Location, r :: Int, v :: Float64) = l.properties[r+3] = v


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


