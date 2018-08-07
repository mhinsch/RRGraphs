
function drop!(cont::C, elem::E) where C, E
	for i in eachindex(cont)
		if cont[i] == elem
			cont[i] = cont[end]
			pop!(cont)
			return i
		end
	end

	return 0
end


