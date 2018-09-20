uint(f) = floor(UInt32, f)

function draw!(pixels, model)

	w = model.world
	xs = size(w.area)[1]
	ys = size(w.area)[2]

	for x in 1:xs, y in 1:ys
		l = world.area[x, y]
		if length(l.people) > 0
			pixels[(x-1)*ys + y] = 0xFFFFFFFF
		else
			pixels[(x-1)*ys + y] = uint(l.properties[1] * 255) << 16 | 0x0
		end
	end
	
	a = rand(model.migrants)
	for k in values(a.knowledge)
		if k.loc == Pos(0, 0)
			continue
		end
		pixels[(k.loc.x-1)* ys + k.loc.y] = 0x000000FF
	end

end

