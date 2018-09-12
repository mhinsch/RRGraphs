using GeoGraph
using DiamondSquare

function setup_location!(loc, terrain)
	set_p!(loc, :friction, terrain)
end

function create_landscape(xsize, ysize, nres)
	world = World([Location(nres) for x=1:xsize, y=1:ysize])

	data = fill(0.0, xsize, ysize)
	myrng(r1, r2) = rand() * (r2 - r1) + r1
	diamond_square(data, myrng, wrap=false)

	mima = extrema(data)

	data .= (data .- mima[1]) ./ (mima[2]-mima[1])

	for x in 1:xsize, y in 1:ysize
		setup_location!(world.area[x, y], data[x, y])
	end

	world
end


# arbitrary values for now
function setup_city!(loc)
	set_p!(loc, :friction, 0.2)
	set_p!(loc, :control, 0.8)
	set_p!(loc, :information, 0.8)
end


function add_cities!(xsize, ysize, ncities, thresh, nres, world)
	nodes, links = create_random_geo_graph(ncities, thresh)
	# rescale to map size
	nodes = map(x -> (floor(Int, x[1]*(xsize-1) + 1), floor(Int, x[2]*(ysize-1)+1)), nodes)

	# cities
	for (x, y) in nodes
		setup_city!(world.area[x, y])
	end

	# TODO set low friction at links
end


function create_world(xsize, ysize, ncities, thresh, nres)
	world = create_landscape(xsize, ysize, nres)
	add_cities!(xsize, ysize, ncities, thresh, nres, world)

	world
end
