# RoutesRumours
simulate migration route dynamics dependent on spread of information

## Requirements

* Julia >= 0.7
* Distributions.jl
* SimpleDirectMediaLayer.jl 
* Parameters.jl
* ArgParse.jl

## Running the simulation

In the package directory:

### GUI

```
julia gui/gui.jl
```

### REPL

```julia
> include("basic_setup.jl")
> pars, model = basic_setup();
> step_simulation!(model, pars)
```

For more sophisticated uses have a look at run.jl.
