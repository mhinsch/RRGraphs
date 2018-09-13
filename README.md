# RoutesRumours
simulate migration route dynamics dependent on spread of information

## Requirements

* Julia >= 0.7
* SimpleDirectMediaLayer Julia package

## Running the simulation

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
> world = create_world(1025, 1025, 100, 0.2, 10)
> model = Model(world, Agent[], Agent[])
> step_simulation!(world)
```
