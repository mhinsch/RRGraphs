using GeoGraph
using DiamondSquare
using Util


function create_landscape(par)
	world = World([Location(par.n_resources) for x=1:par.xsize, y=1:par.ysize])

	data = fill(0.0, par.xsize, par.ysize)
	myrng(r1, r2) = rand() * (r2 - r1) + r1
	diamond_square(data, myrng, hurst=par.hurst, wrap=false)

	mima = extrema(data)

	data .= (data .- mima[1]) ./ (mima[2]-mima[1]) .* par.frict_map_range

	set_p!.(world.area, FRICTION, data)
	set_p!.(world.area, CONTROL, par.control[L_DEFAULT])
	set_p!.(world.area, INFO, par.info[L_DEFAULT])
	setproperty!.(world.area, :opaqueness, par.opacity[L_DEFAULT])
	setproperty!.(world.area, :typ, L_DEFAULT)

	for i in 1:par.n_start_pos
		push!(world.entries, floor(Int, rand()*par.ysize/2 + par.ysize/4))
	end

	world
end


function setup_city!(loc, n_links, par)
	set_p!(loc, FRICTION, par.friction[L_CITY])
	set_p!(loc, CONTROL, par.control[L_CITY])
	set_p!(loc, INFO, par.info[L_CITY])
	for i in 1:par.n_resources
		set_r!(loc, i, par.resources[L_CITY])
	end
	loc.opaqueness = par.opacity[L_CITY]
	loc.typ = L_CITY
end


function setup_link!(loc, par)
	set_p!(loc, FRICTION, par.friction[L_LINK])
	set_p!(loc, CONTROL, par.control[L_LINK])
	loc.typ = L_LINK
end


function add_cities!(world, par)
	nodes, world.links = create_random_geo_graph(par.n_cities, par.link_thresh)
	# rescale to map size
	world.cities = 
		map(x -> (floor(Int, x[1]*(par.xsize-1) + 1), floor(Int, x[2]*(par.ysize-1)+1)), nodes)

	n_links = fill(0, length(world.cities))
	for (i, j) in world.links
		bresenham(world.cities[i]..., world.cities[j]...) do x, y
			setup_link!(world.area[x, y], par)
		n_links[i] += 1
		n_links[j] += 1
		end
	end

	# cities
	for i in eachindex(world.cities)
		x, y = world.cities[i]
		setup_city!(world.area[x, y], n_links[i], par)
	end
end


function create_world(par)
	world = create_landscape(par)
	add_cities!(world, par)

	world
end
