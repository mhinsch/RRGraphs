module Util

export drop!, drop_at!, @set_to_max!

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

end
