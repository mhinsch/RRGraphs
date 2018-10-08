module PageDict

export Page, set!, get, length, iterate

# TODO (at some point in the future)
# make more generic by
# - parameterizing index and collection type
# - implement different search heuristics
# - let users set a "guess" map index -> line


# Since agents move primarily in one direction we know that 
# data will be a lot more sparse in one coordinate than the other.
# Therefore store values in unsorted lists in y-direction which are
# themselves sorted in x-direction.

mutable struct Line{T}
	line :: Int
	values :: Vector{T}
	coords :: Vector{Int}
end


mutable struct Page{T}
	# no elements
	count :: Int
	lines :: Vector{Line{T}}
	Page{T}() where {T} = new(0, Vector{Line{T}}())
end


struct IState
	line :: Int
	col :: Int
end

function Base.iterate(p :: Page{T}, state = IState(1, 1)) where T
	if length(p.lines) < state.line
		return nothing
	end

	i, j = state.line, state.col + 1
	if j > length(p.lines[i].values)
		i, j = i+1, 1
	end

	cur_l = p.lines[state.line]

	(((cur_l.line, cur_l.coords[state.col]), p.lines[state.line].values[state.col]), IState(i, j))
end


# find first index with value >= line
function find_idx_bin(lines, line, start, stop)
#	println(start, " - ", stop)

	# *** check if the value is outside of the range

	sta = lines[start].line 
	# we found it or value is one below range or doesn't exist
	if sta >= line
		return start
	end

	sto = lines[stop].line
	# found it
	if sto == line
		return stop
	# next one after stop is the one
	elseif sto < line
		return stop + 1
	end

	# *** value is in range

	range = stop - start

	# value missing but between start and stop
	if range == 1
		return stop
	end

	# linear interpolation won't do much for small intervals
	mid = range > 5 ? 
		floor(Int, (line-sta) / (sto-sta) * range + start) :
		range ÷ 2 + start

	if lines[mid].line == line
		return mid
	elseif lines[mid].line > line
		return find_idx_bin(lines, line, start+1, mid-1)
	else
		return find_idx_bin(lines, line, mid+1, stop-1)
	end
end


function find_idx(p :: Page{T}, x) where {T}
	nlines = length(p.lines)

	if nlines == 0
		return 1
	end
	
	# this is highly likely later in the simulation, 
	# therefore check explicitly
	if nlines > x && p.lines[x+1].line == x
		return x+1
	end

#	println(">>")
	return find_idx_bin(p.lines, x, 1, nlines)
end


function add_line!(p, x, at)
	par = typeof(p).parameters[1]

	if (length(p.lines) == 0)
		push!(p.lines, Line{par}(x, [], []))
		return 1
	end

	push!(p.lines, p.lines[end])
	# keep the list sorted by shuffling stuff down
	# most additions will be towards the end, so this shouldn't 
	# matter too much in terms of runtime
	for i in (length(p.lines)-1):-1:(at+1)
		p.lines[i] = p.lines[i-1]
	end
	p.lines[at] = Line{par}(x, [], [])

	length(p.lines)
end


function set_value!(line, y, v)
	for i in eachindex(line.coords)
		if y == line.coords[i]
			line.values[i] = v
			return i
		end
	end

	push!(line.values, v)
	push!(line.coords, y)

	length(line.values)
end


function set!(p, v, x, y)
	i = find_idx(p, x)
	if length(p.lines) < i || p.lines[i].line != x
		add_line!(p, x, i)
	end
	
	l = length(p.lines[i].values)
	set_value!(p.lines[i], y, v)
	if l < length(p.lines[i].values)
		p.count += 1
	end

	p
end


function Base.get(p, x, y, default)
	i = find_idx(p, x)
	if i > length(p.lines) || p.lines[i].line != x
		return default
	end

	for j in eachindex(p.lines[i].coords)
		if p.lines[i].coords[j] == y
			return p.lines[i].values[j]
		end
	end

	return default
end


Base.length(p :: Page{T}) where {T} = p.count


end	# module
