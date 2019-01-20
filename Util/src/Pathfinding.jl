module Pathfinding

export path_Astar, path_costs, path_costs_estimate, each_neighbour


using DataStructures


@generated matches(current, target) = current == target ? :(current == target) : :(current in target)


function path_Astar(start, target, path_costs, path_costs_estimate, each_neighbour)
	done = Set{typeof(start)}()

	known = PriorityQueue{typeof(start), Float64}()
	known[start] = path_costs_estimate(start, target)

	previous = Dict{typeof(start), typeof(start)}()

	costs_sofar = Dict(start => 0.0)

	count = 0

	current = start
	found = false

	while length(known) > 0
		#print("*")
		current = dequeue!(known)

		if matches(current, target)
			found = true
			break
		end

		push!(done, current)

		for c in each_neighbour(current)
			if c in done
				continue
			end

			count += 1

			costs_thisway = costs_sofar[current] + path_costs(current, c)

			if haskey(costs_sofar, c) && costs_thisway > costs_sofar[c]
				# no need to explore further since this path is obviously worse
				continue
			end

			costs_sofar[c] = costs_thisway

			known[c] = costs_thisway + path_costs_estimate(c, target)

			previous[c] = current
		end
	end

	#println()

	path = Vector{typeof(start)}()

	if ! found
		return path, count
	end

	n = current # == found target

	while true
		push!(path, n)
		if haskey(previous, n)
			n = previous[n]
		else
			break
		end
	end

	path, count
end	


end
