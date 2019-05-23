uint(f) = floor(UInt32, f)

struct Canvas
	pixels :: Vector{UInt32}
	ysize
end


function put(canvas::Canvas, x, y, colour::UInt32)
	canvas.pixels[(x-1)*canvas.ysize + y] = colour
end

function line(canvas::Canvas, x1, y1, x2, y2, col::UInt32)
	bresenham(x1, y1, x2, y2) do x, y
		put(canvas, x, y, col)
	end
end

xsize(canvas::Canvas) = length(canvas.pixels) ÷ canvas.ysize
ysize(canvas::Canvas) = canvas.ysize
Base.size(canvas::Canvas) = xsize(canvas), ysize(canvas)


clear!(canvas::Canvas) = fill!(canvas.pixels, 0)


Base.copyto!(c1::Canvas, c2::Canvas) = copyto!(c1.pixels, c2.pixels)


alpha(x) = UInt32(x<<24)
alpha(x::F) where {F<:AbstractFloat} = alpha(floor(UInt32, x))

red(x) = UInt32(x<<16)
red(x::F) where {F<:AbstractFloat} = red(floor(UInt32, x))

green(x) = Int32(x<<8)
green(x::F) where {F<:AbstractFloat}  = green(floor(UInt32, x))

blue(x) = UInt32(x)
blue(x::F) where {F<:AbstractFloat}  = blue(floor(UInt32, x))

rgb(r, g, b) = red(r) | green(g) | blue(b)
argb(a, r, g, b) = alpha(a) | red(r) | green(g) | blue(b)


const WHITE = 0xFFFFFFFF


function draw_people!(canvas, model)
	xs, ys = size(canvas)
	for p in model.migrants
		x = scale(p.loc.pos.x, xs) + rand(-5:5)
		x = limit(1, x, xs)
		y = scale(p.loc.pos.y, ys) + rand(-5:5)
		y = limit(1, y, ys)
		put(canvas, x, y, WHITE)
	end
end

scale(x, xs) = floor(Int, x*xs) + 1

scale(p :: Pos, c :: Canvas) = scale(p.x, xsize(c)), scale(p.y, ysize(c))

function draw_link!(canvas, link, value)
	xs, ys = size(canvas)
	x1, y1 = scale(link.l1.pos.x, xs), scale(link.l1.pos.y, ys)
	x2, y2 = scale(link.l2.pos.x, xs), scale(link.l2.pos.y, ys)
	col :: UInt32 = rgb(value * 255, (1.0-value) * 255, 0)
	line(canvas, x1, y1, x2, y2, col)
end
		

function draw_city!(canvas, city, col = nothing)
	xs, ys = size(canvas)

	x = scale(city.pos.x, xs)
	y = scale(city.pos.y, ys)

	xmi = max(1, x-1)
	xma = min(xs, x+1)
	ymi = max(1, y-1)
	yma = min(ys, y+1)

	for x in xmi:xma, y in ymi:yma
		put(canvas, x, y, col == nothing ? blue(255) : col)
	end
end


function draw_bg!(canvas, model)
	w = model.world

	# draw in reverse so that "by foot" links will be drawn first
	for i in length(model.world.links):-1:1
		link = model.world.links[i]
		frict = link.friction / link.distance / 15
		draw_link!(canvas, link, frict)
	end

	for city in model.world.cities
		draw_city!(canvas, city)
	end
end


function draw_visitors!(canvas, model)
	w = model.world

	sum = 0
	ma = 0
	for link in model.world.links
		sum += link.count
		ma = max(ma, link.count)
	end

	if ma == 0
		ma = 1
	end

	for link in model.world.links
		val = link.count / ma
		draw_link!(canvas, link, 0.5 - val/2)
	end

	sum = 0
	ma = 0
	for city in model.world.cities
		sum += city.traffic
		ma = max(ma, city.traffic)
	end

	if ma == 0
		ma = 1
	end

	for city in model.world.cities
		col :: UInt32 = rgb(min(255.0, city.traffic*50), 0, 0)
		draw_city!(canvas, city, col)
	end
end


function draw_rand_knowledge!(canvas, model, agent=nothing)
	if length(model.migrants) < 1
		return nothing
	end

	if agent == nothing
		agent = rand(model.migrants)
	end

	for l in agent.info_link
		if known(l) && known(l.l1) && known(l.l2)
			draw_link!(canvas, l, 0.0)
		end
	end

	for c in agent.info_loc
		if known(c)
			draw_city!(canvas, c)
		end
	end

	prev = Unknown
	for c in agent.plan
		draw_city!(canvas, c, red(255))
		if known(prev)
			draw_link!(canvas, find_link(prev, c), 1.0)
		end
		prev = c
	end

	put(canvas, scale(agent.loc.pos, canvas)..., WHITE)

	agent
end


function draw_rand_social!(canvas, model, depth=1, agent=nothing)
	if length(model.migrants) < 1
		return nothing
	end

	if agent == nothing
		agent = rand(model.migrants)
	end

	todo = Vector{typeof(agent)}()
	next = Vector{typeof(agent)}()
	done = Set{typeof(agent)}()

	push!(next, agent)


	for d in 1:depth
		todo, next = next, todo
		resize!(next, 0)

		v = floor(Int, d / depth * 255)

		for a in todo
			x, y = scale(a.loc.pos, canvas)

			for o in a.contacts
				if o in done
					continue
				end
				xo, yo = scale(o.loc.pos, canvas)
				line(canvas, x, y, xo, yo, rgb(v, 255-v, 0))
				push!(done, o)

				if d < depth
					for o2 in o.contacts
						if ! (o2 in done)
							push!(next, o2)
						end
					end
				end
			end
		end
	end

	agent
end
