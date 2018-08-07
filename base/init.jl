include("rand_geo_graph.jl")


function create_landscape()
end

function create_cities(xsize, ysize, ncities, thresh, nres)
	graph = create_random_geo_graph(ncities, thresh)
end


function create_world(xsize, ysize, ncities, thresh, nres)
	create_landscape()
	create_cities(xsize, ysize, ncities, thresh)


end
