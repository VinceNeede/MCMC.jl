# BaseMCMC

`AbastractBaseMCMC` is a slightly more specific abstract type to work with, which can be used for all the concrete types that only require the `id`, `rng`, `state`, `checkpoint_file` and `save_file`, where the type of the `state` field is a parameter of the type. 

## Types
```@docs
AbstractBaseMCMC
```
## Methods
```@docs
state
rng_state
HDF5.write(::Union{HDF5.File,HDF5.Group}, ::String, ::AbstractBaseMCMC)
```

# Macros
```@docs
@BaseMCMC_def
```