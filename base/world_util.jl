
struct IL_NeighbourIterable
	l :: InfoLocation
end


function each_neighbour(l :: InfoLocation)
	IL_NeighbourIterable(l)
end


function Base.iterate(n :: IL_NeighIter, state)
	i = 0
	if state == nothing
		i = 1
	else
		i = state[2] + 1
	end

	while i <= length(n.l.neighbours)
		if n.l.neighbours[i] == Unknown
			i += 1
			continue
		end
		
		return (n.l.neighbours[i], i)
	end

	nothing
end


function path_costs(l1 :: InfoLocation, l2 :: InfoLocation)
	for i in each_index(l1.neighbours)
		n = l1.neighbours[i]
		if n == l2
			return links[i].friction
		end
	end

	-1.0
end

path_costs_estimate(l1 :: InfoLocation, l2 :: InfoLocation) = distance(l1.pos, l2.pos)






