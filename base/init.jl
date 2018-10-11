using GeoGraph
using DiamondSquare
using Util


function create_landscape(par)
	world = World([Location(par.n_resources) for x=1:par.xsize, y=1:par.ysize])

	data = fill(0.0, par.xsize, par.ysize)
	myrng(r1, r2) = rand() * (r2 - r1) + r1
	diamond_square(data, myrng, wrap=false)

	mima = extrema(data)

	data .= (data .- mima[1]) ./ (mima[2]-mima[1]) .* par.frict_map_range

	set_p!.(world.area, :friction, data)
	set_p!.(world.area, :control, par.control_default)
	set_p!.(world.area, :information, par.inf_default)

	for i in 1:par.n_start_pos
		push!(world.entries, floor(Int, rand()*par.ysize/2 + par.ysize/4))
	end

	world
end


function setup_city!(loc, par)
	set_p!(loc, :friction, par.frict_city)
	set_p!(loc, :control, par.control_city)
	set_p!(loc, :information, par.inf_city)
	for i in 1:par.n_resources
		set_r!(loc, i, par.res_city)
	end
end


function setup_link!(loc, par)
	set_p!(loc, :friction, par.frict_link)
	set_p!(loc, :control, par.control_link)
end


function add_cities!(world, par)
	nodes, world.links = create_random_geo_graph(par.n_cities, par.link_thresh)
	# rescale to map size
	world.cities = 
		map(x -> (floor(Int, x[1]*(par.xsize-1) + 1), floor(Int, x[2]*(par.ysize-1)+1)), nodes)

	# cities
	for (x, y) in world.cities
		setup_city!(world.area[x, y], par)
	end

	for (i, j) in world.links
		bresenham(world.cities[i]..., world.cities[j]...) do x, y
			setup_link!(world.area[x, y], par)
		end
	end
end


function create_world(par)
	world = create_landscape(par)
	add_cities!(world, par)

	world
end
