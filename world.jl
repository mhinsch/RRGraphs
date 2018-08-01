mutable struct Agent
	loc :: Tuple{Int, Int}
	knowledge
	contacts
end


struct Knowledge
	loc :: Tuple{Int, Int}
	properties :: Vector{Float64}
	reliability :: Vector{Float64}	
end


struct Location
	# friction, control, information, resources...
	properties :: Vector{Float64}
	opaqueness :: Float64
	people :: Vector{Agent}
end


mutable struct World
	area :: Matrix{Location}
end


remove_agent!(loc::Location, agent::Agent) = drop!(loc.people, agent)


add_agent!(loc::Location, agent::Agent) = push!(loc.people, agent)


function move!(world, agent, x, y)
	xold, yold = agent.loc
	remove_agent!(world.area[xold, yold], agent)
	loc = find_location(world, x, y)
	agent.loc = loc
	add_agent!(loc, agent)
end

