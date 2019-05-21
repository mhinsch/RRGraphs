module Analysis

export prepare_log, analyse_log, analyse_world

using Util.StatsAccumulator

import Base.print


function print(out::IO, acc :: MaxMinAcc{T}, sep = "\t") where {T}
	print(out, acc.max, sep, acc.min)
end

function print(out::IO, acc :: MVAcc{T}, sep = "\t") where {T}
	res = result(acc)
	print(out, res[1], sep, res[2])
end

function print(out::IO, acc :: AccList, sep = "\t")
	for a in acc.list
		print(out, a, sep)
		print(out, sep)
	end
end

function header(out, name)
	print(out, "mean_$name\tvar_$name\tmax_$name\tmin_$name\t")
end


function prepare_log(logf)
	print(logf, "# ")
	header(logf, "cap")
	header(logf, "n_loc")
	header(logf, "n_link")
	header(logf, "n_plan")
	header(logf, "n_contacts")
	header(logf, "n_steps")
	header(logf, "freq_plan")
	header(logf, "count")
	header(logf, "traffic")
	print(logf, "n_migrants\t")
	print(logf, "n_arrived")
	println(logf)
end

function analyse_log(model, logf)
	accs = AccList[]

	for i in 1:9
		acc = AccList()
		push!(acc.list, MVAcc{Float64}())
		push!(acc.list, MaxMinAcc{Float64}())
		push!(accs, acc)
	end

	for a in model.migrants
		next = 0
		add!(accs[next+=1], a.capital)
		add!(accs[next+=1], Float64(a.n_locs))
		add!(accs[next+=1], Float64(a.n_links))
		add!(accs[next+=1], Float64(length(a.plan)))
		add!(accs[next+=1], Float64(length(a.contacts)))
		add!(accs[next+=1], Float64(a.steps))
		add!(accs[next+=1], Float64(a.planned / (a.steps + 0.00001)))
	end


	for ex in model.world.exits
		add!(accs[end-1], Float64(ex.count))
		add!(accs[end], Float64(ex.traffic))
	end

	for a in accs
		print(logf, a)
	end

	print(logf, length(model.migrants), "\t", length(model.people) - length(model.migrants), "\t")

	println(logf)
	flush(logf)
end
	

function analyse_world(model, out_cities, out_links)
	println(out_cities, "# id	x	y	type	qual	N	links	count")
	println(out_links, "# id	type	l1	l2	friction	count")

	w = model.world

	for c in w.cities
		println(out_cities, c.id, "\t", c.pos.x, "\t", c.pos.y, "\t", c.typ, "\t", 
			c.quality, "\t", length(c.people), "\t", length(c.links), "\t", c.count)
	end

	for l in w.links
		println(out_links, l.id, "\t", l.typ, "\t", l.l1.id, "\t", l.l2.id, "\t", l.friction, "\t",
			l.count)
	end
end

function prepare_out(outf)
end

end # module
