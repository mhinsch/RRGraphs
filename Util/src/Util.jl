module Util


export drop!, drop_at!, @set_to_max!, @update!, bresenham, PageDict, limit, valley, distance, Pathfinding


function drop!(cont, elem)
	for i in eachindex(cont)
		if cont[i] == elem
			drop_at!(cont, i)
			return i
		end
	end

	# TODO convert into index type
	return 0
end


function drop_at!(cont, i)
	cont[i] = cont[end]
	pop!(cont)
end


macro set_to_max!(a, b)
	esc(:(a > b ? (b = a) : (a=b)))
end


macro update!(fun, args...)
   esc( :( ($(args...),) = $fun($(args...)) ) )
end


function sigmoid(x, alpha, mid)
	c = mid/(1.0-mid)
	x^alpha/(((1.0-x)*c)^alpha + x^alpha)
end


# 0 at bottom, sigmoid to 1 on both sides, f(bottom +- steep) == 0.5
valley(x, bottom, steep, alpha=3) = 
	abs((x-bottom)^alpha) / (steep^alpha + abs((x-bottom)^alpha))



limit(mi, v, ma) = min(ma, max(v, mi))


distance(x1, y1, x2, y2) = sqrt((x1-x2)^2 + (y1-y2)^2)


# based on this code:
# https://stackoverflow.com/questions/40273880/draw-a-line-between-two-pixels-on-a-grayscale-image-in-julia
function bresenham(f :: Function, x1::Int, y1::Int, x2::Int, y2::Int)
	#println("b: ", x1, ", ", y1)
	#println("b: ", x2, ", ", y2)
	# Calculate distances
	dx = x2 - x1
	dy = y2 - y1

	# Determine how steep the line is
	is_steep = abs(dy) > abs(dx)

	# Rotate line
	if is_steep == true
		x1, y1 = y1, x1
		x2, y2 = y2, x2
	end

	# Swap start and end points if necessary 
	if x1 > x2
		x1, x2 = x2, x1
		y1, y2 = y2, y1
	end
	# Recalculate differentials
	dx = x2 - x1
	dy = y2 - y1

	# Calculate error
	error = round(Int, dx/2.0)

	if y1 < y2
		ystep = 1
	else
		ystep = -1
	end

	# Iterate over bounding box generating points between start and end
	y = y1
	for x in x1:x2
		if is_steep == true
			coord = (y, x)
		else
			coord = (x, y)
		end

		f(coord[1], coord[2])

		error -= abs(dy)

		if error < 0
			y += ystep
			error += dx
		end
	end

end



include("page.jl")
include("Pathfinding.jl")

end
