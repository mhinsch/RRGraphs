using ArgParse
using REPL

"add all fields of a type as command line arguments"
function fields_as_args!(arg_settings, t :: Type)
	fields = fieldnames(t)
	for f in fields
		fdoc =  REPL.stripmd(REPL.fielddoc(t, f))
		add_arg_table(arg_settings, ["--" * String(f)], Dict(:help => fdoc))
	end
end

"create object from command line arguments"
function create_from_args(args, t :: Type)
	par_expr = Expr(:call, t.name.name)

	fields = fieldnames(t)

	for key in eachindex(args)
		if args[key] == nothing || !(key in fields)
			continue
		end
		val = parse(fieldtype(t, key), args[key])
		push!(par_expr.args, Expr(:kw, key, val))
	end

	eval(par_expr)
end


function get_parfile()
	if length(ARGS) > 1 && ARGS[1][1] != '-'
		parfile = ARGS[1]
		deleteat!(ARGS, 1)
	else
		parfile = "base/params.jl"
	end

	parfile
end


function save_params(out_name, p)
	open(out_name, "w") do out
		for f in fieldnames(typeof(p))
			println(out, f, "\t", getfield(p, f))
		end
	end
end

