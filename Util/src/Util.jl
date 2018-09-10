module Util

export drop!

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
