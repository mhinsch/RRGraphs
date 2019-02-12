#!/usr/bin/env julia

using Random

push!(LOAD_PATH, pwd())

using Analysis

include("base/world.jl")
include("base/init.jl")
include("base/simulation.jl")
include("base/setup.jl")


function run(p, n_steps, log_file)
	Random.seed!(p.rand_seed_world)
	w = create_world(p);

	Random.seed!(p.rand_seed_sim)
	m = Model(w, Agent[], Agent[]);

	for i in 1:n_steps
		step_simulation!(m, p)
		analyse_log(m, log_file)
		println(i)
		flush(stdout)
	end
end


include(get_parfile())
	

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
