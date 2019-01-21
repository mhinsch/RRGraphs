
struct IL_NeighIter
	l :: InfoLocation
end


function each_neighbour(l :: InfoLocation)
	IL_NeighIter(l)
end


function Base.iterate(n :: IL_NeighIter, i=1)
	while i <= length(n.l.neighbours)
		if n.l.neighbours[i] == Unknown
			i += 1
			continue
		end
		
		return (n.l.neighbours[i], i+1)
	end

	nothing
end


function path_costs(l1 :: InfoLocation, l2 :: InfoLocation)
	for i in eachindex(l1.neighbours)
		n = l1.neighbours[i]
		if n == l2
			return l1.links[i].friction.value
		end
	end

	-1.0
end


path_costs_estimate(l1 :: InfoLocation, l2 :: InfoLocation) = distance(l1.pos, l2.pos)

function path_costs_estimate(l1 :: InfoLocation, l2 :: Vector{InfoLocation})
	est = path_costs_estimate(l1, l2[1])
	for i in 2:length(l2)
		estt = path_costs_estimate(l1, l2[i])
		if estt < est
			est = estt
		end
	end

	est
end




