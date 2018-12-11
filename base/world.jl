using Util
using Util.PageDict


# simple grid coords for now
struct Pos
	x :: Float64
	y :: Float64
end


distance(p1 :: Pos, p2 :: Pos) = distance(p1.x, p1.y, p2.x, p2.y)


const Nowhere = Pos(-1.0, -1.0)


# a piece of knowledge an agent has about a location
mutable struct InfoLocation
	pos :: Pos
	id :: Int
	# property values the agent expects
	resources :: Float64
	quality :: Float64
	# how certain it thinks they are
	trust_res :: Float64
	trust_qual :: Float64

	links :: Vector{InfoLink}
	neighbours :: Vector{InfoLocation}
end


const Unknown = InfoLocation(Nowhere, 0, 0.0, 0.0, 0.0, 0.0, [])


mutable struct InfoLink
	l1 :: InfoLocation
	l2 :: InfoLocation
	friction :: Float64
	trust :: Float64
end


# migrants
mutable struct Agent
	# current position
	loc :: Location
	# what it thinks it knows about the world
	info :: Vector{InfoLocation}
	# abstract capital, includes time & money
	capital :: Float64
	# people at home & in target country, other migrants
	contacts :: Vector{Agent}
end

Agent(l :: Pos, c :: Float64) = Agent(l, InfoLocation[], c, Agent[])


function add_to_contacts!(agent, a)
	if a in agent.contacts
		return
	end

	push!(agent.contacts, a)
end


mutable struct Location
	id :: Int
	resources :: Float64
	quality :: Float64
	people :: Vector{Agent}

	links :: Vector{Link}

	pos :: Pos

	count :: Int
end


# construct empty location
Location(p :: Pos, i) = Location(i, 0.0, 0.0, Agent[], Link[], p, 0)
Location() = Location(Nowhere, 0)


distance(l1 :: Location, l2 :: Location) = distance(l1.pos, l2.pos)


mutable struct Link
	l1 :: Location
	l2 :: Location
	friction :: Float64
	distance :: Float64
end

Link(l1, l2) = Link(l1, l2, 0, 0)


mutable struct World
	cities :: Vector{Location}
	links :: Vector{Link}
	entries :: Vector{Float64}
	exits :: Vector{Location}
end

World() = World([], [], [], [])



remove_agent!(loc::Location, agent::Agent) = drop!(loc.people, agent)


function add_agent!(loc::Location, agent::Agent) 
	push!(loc.people, agent)
	loc.count += 1
end


remove_agent!(world, agent) = remove_agent!(agent.loc, agent)


function move!(world, agent, loc)
	remove_agent!(world, agent)
	agent.loc = loc
	add_agent!(loc, agent)
end


