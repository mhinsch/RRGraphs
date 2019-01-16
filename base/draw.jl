uint(f) = floor(UInt32, f)

struct Canvas
	pixels :: Vector{UInt32}
	ysize
end


function put(canvas::Canvas, x, y, colour::UInt32)
	canvas.pixels[(x-1)*canvas.ysize + y] = colour
end


Base.size(canvas::Canvas) = (length(canvas.pixels) ÷ canvas.ysize, canvas.ysize)


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
		x = scale(p.loc.pos.x, xs) + rand(-2:2)
		x = limit(1, x, xs)
		y = scale(p.loc.pos.y, ys) + rand(-2:2)
		y = limit(1, y, ys)
		put(canvas, x, y, WHITE)
	end
end

scale(x, xs) = floor(Int, x*xs) + 1

function draw_link!(canvas, link, value)
	xs, ys = size(canvas)
	x1, y1 = scale(link.l1.pos.x, xs), scale(link.l1.pos.y, ys)
	x2, y2 = scale(link.l2.pos.x, xs), scale(link.l2.pos.y, ys)
	col :: UInt32 = rgb(value * 255, (1.0-value) * 255, 0)
	bresenham(x1, y1, x2, y2) do x, y
		put(canvas, x, y, col)
	end
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
		frict = link.friction / link.distance / 10.1
		draw_link!(canvas, link, frict)
	end

	for city in model.world.cities
		draw_city!(canvas, city)
	end
end


function draw_visitors!(canvas, model)
	w = model.world

	for link in model.world.links
		val = min(link.count / 100, 1.0)
		draw_link!(canvas, link, 0.5 - val/2)
	end

	for city in model.world.cities
		draw_city!(canvas, city, red(length(city.people)))
	end
end


function draw_rand_knowledge!(canvas, model)
	if length(model.migrants) < 1
		return
	end

	agent = rand(model.migrants)

	for l in agent.info_link
		if l != UnknownLink && l.l1 != Unknown && l.l2 != Unknown
			draw_link!(canvas, l, 0.0)
		end
	end

	for c in agent.info_loc
		if c != Unknown
			draw_city!(canvas, c)
		end
	end

	prev = Unknown
	for c in agent.plan
		draw_city!(canvas, c, red(255))
		if prev != Unknown
			draw_link!(canvas, find_link(prev, c), 1.0)
		end
		prev = c
	end

	xs, ys = size(canvas)

	put(canvas, scale(agent.loc.pos.x, xs), scale(agent.loc.pos.y, ys), WHITE)
end

