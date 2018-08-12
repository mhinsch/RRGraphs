using GeoGraph
using DiamondSquare

function setup_location!(loc, terrain)
	set_p!(loc, :friction, (terrain + 100.0)/200.0)
end

function create_landscape(xsize, ysize)
	world = World(Matrix{Location}(xsize, ysize))

	data = Matrix{Float64}(xsize, ysize)
	myrng(r1, r2) = rand() * (r2 - r1) + r1
	diamond_square(data, myrng, wrap=false)

	for x in 1:xsize, y in 1:ysize
		setup_location!(world.area[x, y], data[x, y])
	end

	world
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

	# set low friction at links
end


function create_world(xsize, ysize, ncities, thresh, nres)
	world = create_landscape(xsize, ysize)
	add_cities!(xsize, ysize, ncities, thresh, nres, world)

	world
end
