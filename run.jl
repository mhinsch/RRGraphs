#!/usr/bin/env julia

using Random
using ArgParse
using REPL

push!(LOAD_PATH, pwd())
include("base/world.jl")
include("base/init.jl")
include("base/simulation.jl")
include("base/params.jl")

function fields_as_args!(arg_settings, t :: Type)
	fields = fieldnames(t)
	for f in fields
		fdoc =  REPL.stripmd(REPL.fielddoc(t, f))
		add_arg_table(arg_settings, ["--" * String(f)], Dict(:help => fdoc))
	end
end

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


function run(p, n_steps)
	Random.seed!(p.rand_seed_world)
	w = create_world(p);

	Random.seed!(p.rand_seed_sim)
	m = Model(w, Agent[], Agent[]);

	for i in 1:n_steps
		step_simulation!(m, p)
	end
end


const arg_settings = ArgParseSettings("run simulation", autofix_names=true)

add_arg_table(arg_settings, ["--n-steps", "-n"], Dict(:help => "number of simulation steps", 
	:arg_type => Int64, :default => 300))

add_arg_group(arg_settings, "simulation parameters")
fields_as_args!(arg_settings, Params)

const args = parse_args(arg_settings, as_symbols=true)

const p = create_from_args(args, Params)

const n_steps = args[:n_steps] 

println(p)

run(p, n_steps)
