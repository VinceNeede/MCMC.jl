# PiMCMC

## Types
```@docs
AbstractPiMCMC
PiMCMC
```
# Methods
```@docs
state(::AbstractPiMCMC)
rng(::AbstractPiMCMC)
sample(::AbstractPiMCMC)
update!(::AbstractPiMCMC, ::Vector{Float64})
observables(::AbstractPiMCMC)
Base.write(::HDF5.File, ::String, AbstractPiMCMC)
rng_state(::PiMCMC)
```