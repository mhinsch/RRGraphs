# RoutesRumours
simulate migration route dynamics dependent on spread of information

## Requirements

* Julia >= 0.7
* SimpleDirectMediaLayer.jl 
* Parameters.jl

## Running the simulation

In the package directory:

### GUI

```
julia gui/gui.jl
```

### REPL

```julia
> push!(LOAD_PATH, ".")
> include("base/world.jl")
> include("base/init.jl")
> include("base/simulation.jl")
> include("base/params.jl")
> const pars = Params() # use default values
> world = create_world(pars)
> model = Model(world, Agent[], Agent[])
> step_simulation!(world, pars)
```
