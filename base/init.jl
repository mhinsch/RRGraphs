using GeoGraph
using DiamondSquare
using Util


function setup_city!(loc, par)
	loc.quality = rand()
	loc.resources = rand()
end


function setup_link!(link, dist, typ, par)
	link.distance = distance(link.l1, link.l2)
	link.friction = link.distance * par.dist_scale[typ]
end


function add_link(world, c1, c2, typ, par)
	push!(world.links, Link(c1, c2))
	push!(c1.links, world.links[end])
	push!(c2.links, world.links[end])
	setup_link!(world.links[end], typ, par)
end


function add_cities!(world, par)
	nodes, world.links = create_random_geo_graph(par.n_cities, par.link_thresh)

	# cities
	for n in nodes
		push!(world.cities, Location(Pos(n...), STD, length(world.citiesi)+1))
		setup_city!(world.cities[end], par)
	end

	for (i, j) in world.links
		add_link!(world.cities[i], world.cities[j], 1, par)
	end
end


function add_entries!(world, par)
	for i in 1:par.n_entries
		y = rand()
		x = 0
		push!(World.cities, Location(Pos(x, y), ENTRY, length(world.cities)+1))
		push!(World.entries, world.cities[end])
		# exits are linked to every city (but badly)
		for c in World.cities
			add_link!(c, World.entries[end], 2, par)
		end
	end
end

		
function add_exits!(world, par)
	for i in 1:par.n_exits
		y = rand()
		x = 1
		push!(World.cities, Location(Pos(x, y), EXIT, length(world.cities)+1))
		push!(World.exits, world.cities[end])
		# exits are linked to every city (but badly)
		for c in World.cities
			add_link!(c, World.exits[end], 2, par)
		end
	end
end

		


function create_world(par)
	world = World()
	add_cities!(world, par)
	add_entries!(world, par)
	add_exits!(world, par)

	world
end
