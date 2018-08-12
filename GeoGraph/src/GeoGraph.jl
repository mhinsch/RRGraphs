module GeoGraph

export create_random_geo_graph

function create_random_geo_graph(nnodes :: Int64, thresh :: Float64)
	sq_thresh = thresh * thresh

	sq_dist(n1, n2) = (n1[1] - n2[1])^2 + (n1[2] - n2[2])^2

	nodes = Vector{Tuple{Float64, Float64}}()
	links = Vector{Tuple{Int64, Int64}}()

	for i in 1:nnodes
		new_node = (rand(), rand())
		for j in eachindex(nodes)
			if sq_dist(nodes[j], new_node) < sq_thresh
				push!(links, (i, j))
			end
		end
		push!(nodes, new_node)
	end

	(nodes, links)
end


end
