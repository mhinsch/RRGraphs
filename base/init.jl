using GeoGraph

function create_landscape(xsize, ysize)
	World(Matrix{Location}(xsize, ysize))
end


function setup_city!(loc)
	set_p(loc, :friction, 0.2)
	set_p(loc, :control, 0.8)
	set_p(loc, :information, 0.8)
end


function add_cities!(xsize, ysize, ncities, thresh, nres, world)
	nodes, links = create_random_geo_graph(ncities, thresh)
	# rescale to map size
	nodes = map(x -> (x[1]*xsize, x[2]*ysize), nodes)

	# cities
	for (x, y) in nodes
		setup_city!(world.area[x, y])
	end
end


function create_world(xsize, ysize, ncities, thresh, nres)
	world = create_landscape(xsize, ysize)
	add_cities!(xsize, ysize, ncities, thresh, nres, world)


end
