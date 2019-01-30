using Random

push!(LOAD_PATH, pwd())
include("base/world.jl")
include("base/init.jl")
include("base/simulation.jl")
include("base/params.jl")

p = Params()

Random.seed!(p.rand_seed_world)
const w = create_world(p);

Random.seed!(p.rand_seed_sim)
const m = Model(w, Agent[], Agent[]);

