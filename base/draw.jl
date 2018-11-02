uint(f) = floor(UInt32, f)

struct Canvas
	pixels :: Vector{UInt32}
	ysize
end


function put(canvas::Canvas, x, y, colour::UInt32)
	canvas.pixels[(x-1)*canvas.ysize + y] = colour
end

alpha(x) = UInt32(x<<24)
red(x) = UInt32(x<<16)
green(x) = UInt32(x<<8)
blue(x) = UInt32(x)

rgb(r, g, b) = red(r) & green(g) & blue(b)
argb(a, r, g, b) = alpha(a) & red(r) & green(g) & blue(b)



const WHITE = 0xFFFFFFFF


function draw_people!(canvas, model)
	for p in model.migrants
		put(canvas, p.loc.x, p.loc.y, WHITE)
	end
end


function draw_bg!(canvas, model)
	w = model.world
	xs = size(w.area)[1]
	ys = size(w.area)[2]

	for x in 1:xs, y in 1:ys
		l = w.area[x, y]
		if l.typ == L_DEFAULT
			put(canvas, x, y, red(uint(get_p(w.area[x, y], FRICTION) * 255)))
		elseif l.typ == L_LINK
			put(canvas, x, y, green(126))
		else	# city
			put(canvas, x, y, blue(255))
		end
	end
end


function draw_visitors!(canvas, model)
	w = model.world
	xs = size(w.area)[1]
	ys = size(w.area)[2]

	for x in 1:xs, y in 1:ys
		put(canvas, x, y, green(min(w.area[x, y].count, 255)))
	end
end



function draw_rand_knowledge!(canvas, model)
	if length(model.migrants) < 1
		return
	end

	a = rand(model.migrants)
	for (l, k) in a.boring
		put(canvas, l[1], l[2], blue(round(UInt32, k * 100 + 150))) 
	end
	for (l, k) in a.knowledge
		put(canvas, l[1], l[2], green(round(UInt32, sum(k.trust) * 100 + 150)))
	end

	for p in a.targets
		put(canvas, p.x, p.y, red(UInt32(255)))
	end

	put(canvas, a.loc.x, a.loc.y, WHITE)
end

