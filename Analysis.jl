module Analysis

export prepare_log, analyse_log

using Util.StatsAccumulator

function log(acc :: MaxMinAcc{T}, logf, sep = "\t") where {T}
	print(logf, acc.max, sep, acc.min)
end

function log(acc :: MVAcc{T}, logf, sep = "\t") where {T}
	res = result(acc)
	print(logf, res[1], sep, res[2])
end

function log(acc :: AccList, logf, sep = "\t")
	for a in acc.list
		log(a, logf, sep)
		print(logf, sep)
	end
end

function header(logf, name)
	print(logf, "mean_$name\tvar_$name\tmax_$name\tmin_$name\t")
end


function prepare_log(logf)
	print(logf, "# ")
	header(logf, "cap")
	header(logf, "n_loc")
	header(logf, "n_link")
	header(logf, "n_plan")
	header(logf, "n_contacts")
	header(logf, "count")
	print(logf, "n_migrants")
	print(logf, "n_arrived")
	println(logf)
end

function analyse_log(model, logf)
	accs = AccList[]

	for i in 1:6
		acc = AccList()
		push!(acc.list, MVAcc{Float64}())
		push!(acc.list, MaxMinAcc{Float64}())
		push!(accs, acc)
	end

	for a in model.migrants
		add!(accs[1], a.capital)
		add!(accs[2], Float64(a.n_locs))
		add!(accs[3], Float64(a.n_links))
		add!(accs[4], Float64(length(a.plan)))
		add!(accs[5], Float64(length(a.contacts)))
	end

	for ex in model.world.exits
		add!(accs[6], Float64(ex.count))
	end

	for a in accs
		log(a, logf)
	end

	print(logf, length(model.migrants), "\t", length(model.people) - length(model.migrants), "\t")

	println(logf)
	flush(logf)
end
	

function prepare_out(outf)
end


function analyse_out(model, outf)
	accs = AccList[]

	acc = AccList()
	push!(acc.list, MVAcc{Float64}())
	push!(acc.list, MaxMinAcc{Float64}())
	push!(accs, acc)
		
	for ex in model.world.exits
		add!(acc, Float64(ex.count))
	end
end


end # module
