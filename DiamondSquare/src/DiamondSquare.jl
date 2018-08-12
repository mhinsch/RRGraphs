module DiamondSquare


export diamond_square


Point = Tuple{Int, Int}


@inline function generate_midpoint!(data, 
	corners :: NTuple{N, Point}, 
	offset :: Point, rand :: T) where {T, N}
	
	# println("mid: ", corners, " ", offset)

	sum = T(0.0)
	count = 0
	
	for i in 1:length(corners)
		@inbounds sum += data[corners[i][1], corners[i][2]]
		count += 1
	end
	# set midpoint to average + disturbance
	@inbounds data[(corners[1] .+ offset)...] = sum / count + rand
end


function diamond_square(data, rng; wrap::Bool = true, hurst = 0.8, vrange = 100.0, start = 0.0)
	xs = size(data)[1]
	ys = size(data)[2]

	xones = count_ones(wrap ? xs : xs-1)
	yones = count_ones(wrap ? ys : ys-1)
	@assert (xones == 1 && yones == 1)

	E = eltype(data)

	range = E(vrange)
	edge_start = E(start)

	roughness = E(0.5)^(2*hurst)
	
	over(x, xs) = wrap ? mod1(x, xs) : (x<1 || x>xs ? 1 : x)

	wx(x) = over(x, xs)
	wy(y) = over(y, ys)

	# max values are 1 beyond the edge for wrap==true
	max_x = xs + (wrap ? 1 : 0)
	max_y = ys + (wrap ? 1 : 0)

	fill!(data, E(0.0))

	# initialize edges
	data[1, 1] = edge_start
	# these are redundant for wrap == true
	data[wx(max_x), 1] = edge_start
	data[1, wy(max_y)] = edge_start
	data[wx(max_x), wy(max_y)] = edge_start

	grid = max(max_x, max_y) - 1
	end_x = max_x - 1
	end_y = max_y - 1

	while grid > 1
		grid_half = grid ÷ 2

		# println("gh ", grid, " ", grid_half)

		# diamond step

		@simd for step_y in 1:grid:end_y
		@simd for step_x in 1:grid:end_x
			# println(step_y, " ", step_x)
			generate_midpoint!(data, (
					(step_x, step_y),
					(wx(step_x + grid), step_y),
					(wx(step_x + grid), wy(step_y + grid)),
					(step_x, wy(step_y + grid))),
				(grid_half, grid_half), rng(-range, range))
		end
		end

		# square step
		
		last_step_y = 0
		@simd for step_y in 1:grid:end_y
			last_step_x = 0
			@simd for step_x in 1:grid:end_x
				# top
				generate_midpoint!(data, (
						(step_x, step_y),
						(step_x + grid_half, step_y + grid_half),
						(wx(step_x + grid), step_y),
						(step_x + grid_half, wy(step_y - grid_half))),
					(grid_half, 0), rng(-range, range))
				# left
				generate_midpoint!(data, (
						(step_x, step_y),
						(step_x + grid_half, step_y + grid_half),
						(step_x, wy(step_y + grid)),
						(wx(step_x - grid_half), step_y + grid_half)),
					(0, grid_half), rng(-range, range))

				last_step_x = step_x
			end

			# right edge of last square
			if ! wrap
				generate_midpoint!(data, (
						(last_step_x + grid, step_y),
		#				(0, 0),	# outside, ignore
						(last_step_x + grid, step_y + grid),
						(last_step_x + grid_half, step_y + grid_half)),
					(0, grid_half), rng(-range, range))
			end

			last_step_y = step_y
		end

		# bottom edge
		if ! wrap
			@simd for step_x in 1:grid:end_x
				generate_midpoint!(data, (
						(step_x, last_step_y + grid),
		#				(0, 0), # outside, ignore
						(step_x + grid, last_step_y + grid),
						(step_x + grid_half, last_step_y + grid_half)),
					(grid_half, 0), rng(-range, range))
			end
		end

		grid = grid_half
		range *= roughness
	end
end

end # module
