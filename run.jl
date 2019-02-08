#!/usr/bin/env julia

using Random
using ArgParse
using REPL

push!(LOAD_PATH, pwd())

using Analysis

include("base/world.jl")
include("base/init.jl")
include("base/simulation.jl")
include("base/params.jl")

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


function save_params(out_name, p)
	open(out_name, "w") do out
		for f in fieldnames(typeof(p))
			println(out, f, "\t", getfield(p, f))
		end
	end
end
		

function run(p, n_steps, log_file)
	Random.seed!(p.rand_seed_world)
	w = create_world(p);

	Random.seed!(p.rand_seed_sim)
	m = Model(w, Agent[], Agent[]);

	for i in 1:n_steps
		step_simulation!(m, p)
		analyse_log(m, log_file)
		println(i)
	end
end


const arg_settings = ArgParseSettings("run simulation", autofix_names=true)

@add_arg_table arg_settings begin
	"--n-steps", "-n"
		help = "number of simulation steps" 
		arg_type = Int
		default = 300
	"--par-file", "-p"
		help = "file name for parameters"
		default = "params.txt"
	"--out-file", "-o"
		help = "file name for data output"
		default = "output.txt"
	"--log-file", "-l"
		help = "file name for log"
		default = "log.txt"
end

add_arg_group(arg_settings, "simulation parameters")
fields_as_args!(arg_settings, Params)

const args = parse_args(arg_settings, as_symbols=true)
const p = create_from_args(args, Params)


save_params(args[:par_file], p)


const n_steps = args[:n_steps] 

const logf = open(args[:log_file], "w")
#const outf = open(args[:out_file], "w")

prepare_log(logf)
#prepare_out(outf)
run(p, n_steps, logf)

#close(outf)
close(logf)
