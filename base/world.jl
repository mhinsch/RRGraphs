using Util
using Util.PageDict


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
	id :: Int
	l1 :: InfoLocation
	l2 :: InfoLocation
	friction :: Float64
	trust :: Float64
end

const UnknownLink = InfoLink(0, Unknown, Unknown, 0.0, 0.0)

other(link, loc) = loc == link.l1 ? link.l2 : link.l1


# migrants
mutable struct Agent
	# current position
	loc :: Location
	in_transit :: Bool
	# what it thinks it knows about the world
	info_loc :: Vector{InfoLocation}
	info_target :: Vector{InfoLocation}
	info_link :: Vector{InfoLink}
	plan :: Vector{InfoLocation}
	# abstract capital, includes time & money
	capital :: Float64
	# people at home & in target country, other migrants
	contacts :: Vector{Agent}
end

Agent(l :: Location, c :: Float64) = 
	Agent(l, true, 
		InfoLocation[], InfoLocation[], InfoLink[], InfoLocation[], 
		c, Agent[])


# get the agent's info on a location
knows(agent, l::Location) = agent.info_loc[l.id]
# get the agent's info on its current location
knows_current(agent) = knows_at(agent.loc)

# get the agent's info on a link
knows(agent, l::Link) = agent.info_link[l.id]

target(agent) = length(agent.info_target) > 0 ? agent.info_target[1] : Unknown


learn!(agent, info :: InfoLocation) = agent.info_loc[info.id] = info
learn!(agent, info :: InfoLink) = agent.info_link[info.id] = info


function add_to_contacts!(agent, a)
	if a in agent.contacts
		return
	end

	push!(agent.contacts, a)
end


@enum LOC_TYPE STD=1 ENTRY EXIT

mutable struct Location
	id :: Int
	typ :: LOC_TYPE
	resources :: Float64
	quality :: Float64
	people :: Vector{Agent}

	links :: Vector{Link}

	pos :: Pos

	count :: Int
end


# construct empty location
Location(p :: Pos, t, i) = Location(i, t, 0.0, 0.0, Agent[], Link[], p, 0)
Location() = Location(Nowhere, STD, 0)


distance(l1 :: Location, l2 :: Location) = distance(l1.pos, l2.pos)


mutable struct Link
	id :: Int
	l1 :: Location
	l2 :: Location
	friction :: Float64
	distance :: Float64
end

Link(l1, l2) = Link(l1, l2, 0, 0)


mutable struct World
	cities :: Vector{Location}
	links :: Vector{Link}
	entries :: Vector{Location}
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


