using Util
using Util.PageDict


struct Pos
	x :: Float64
	y :: Float64
end


const Nowhere = Pos(-1.0, -1.0)


distance(p1 :: Pos, p2 :: Pos) = Util.distance(p1.x, p1.y, p2.x, p2.y)


# a piece of knowledge an agent has about a location
mutable struct InfoLocationT{L}
	pos :: Pos
	id :: Int
	# property values the agent expects
	resources :: Float64
	quality :: Float64
	# how certain it thinks they are
	trust_res :: Float64
	trust_qual :: Float64

	links :: Vector{L}
	neighbours :: Vector{InfoLocationT{L}}
end


mutable struct InfoLink
	id :: Int
	l1 :: InfoLocationT{InfoLink}
	l2 :: InfoLocationT{InfoLink}
	friction :: Float64
	trust :: Float64
end


InfoLocation = InfoLocationT{InfoLink}


const Unknown = InfoLocation(Nowhere, 0, 0.0, 0.0, 0.0, 0.0, [], [])
const UnknownLink = InfoLink(0, Unknown, Unknown, 0.0, 0.0)


otherside(link, loc) = loc == link.l1 ? link.l2 : link.l1

# no check for validity etc.
add_link!(loc, link) = push!(loc.links, link)

add_neighbour!(loc, neigh) = push!(loc.neighbours, neigh)


# migrants
mutable struct Agent
	# current real position
	loc
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

Agent(l, c :: Float64) = 
	Agent(l, true, 
		InfoLocation[], InfoLocation[], InfoLink[], InfoLocation[], 
		c, Agent[])


target(agent) = length(agent.info_target) > 0 ? agent.info_target[1] : Unknown

arrived(agent) = agent.loc.typ == EXIT


function add_info!(agent, info :: InfoLocation, typ = STD) 
	agent.info_loc[info.id] = info
	if typ == EXIT
		push!(agent.info_target, info)
	end
end

function add_info!(agent, info :: InfoLink) 
	agent.info_link[info.id] = info
end
	


function add_contact!(agent, a)
	if a in agent.contacts
		return
	end

	push!(agent.contacts, a)
end


@enum LOC_TYPE STD=1 ENTRY EXIT

mutable struct LocationT{L}
	id :: Int
	typ :: LOC_TYPE
	resources :: Float64
	quality :: Float64
	people :: Vector{Agent}

	links :: Vector{L}

	pos :: Pos

	count :: Int
end


distance(l1, l2) = distance(l1.pos, l2.pos)


@enum LINK_TYPE FAST=1 SLOW

mutable struct Link
	id :: Int
	typ :: LINK_TYPE
	l1 :: LocationT{Link}
	l2 :: LocationT{Link}
	friction :: Float64
	distance :: Float64
	count :: Int
end


Link(id, t, l1, l2) = Link(id, t, l1, l2, 0, 0, 0)


LocationT{L}(p :: Pos, t, i) where {L} = LocationT{L}(i, t, 0.0, 0.0, Agent[], L[], p, 0)
# construct empty location
#LocationT{L}() where {L} = LocationT{L}(Nowhere, STD, 0)

Location = LocationT{Link}


# get the agent's info on a location
info(agent, l::Location) = agent.info_loc[l.id]
# get the agent's info on its current location
info_current(agent) = info(agent, agent.loc)
# get the agent's info on a link
info(agent, l::Link) = agent.info_link[l.id]

# get the agent's info on a location
knows(agent, l::Location) = info(agent, l) != Unknown
# get the agent's info on a link
knows(agent, l::Link) = info(agent, l) != UnknownLink

function find_link(from, to)
	for l in from.links
		if otherside(l, from) == to
			return l
		end
	end

	nothing
end


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


