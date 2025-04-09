# Create a Custom MCMC
MCMC tries to be as general as possible, making extensive use of `julia` subtyping. However, this also means that it is often necessary to implement a new concrete type for the MCMC we want to perform.

This example aims to walk through the implementation of `PiMCMC` to understand how a concrete `MCMC` type should be created. The only difference is that `PiMCMC` actually relies on the `AbstractBaseMCMC` structure and uses the [`@BaseMCMC_def`](@ref) macro, while here we will implement the concrete type directly for simplicity.

## Define the Type
All the `AbstractMCMC` subtypes must have `id`, `rng`, `save_file`, `checkpoint_file` defined as either fields or methods. In the case of `PiMCMC` these are defined as fields. We also need a field to store the state of chain, in this case the 2D point in the $[0, 1]\times[0, 1]$ square. We are going to use the `Base.@kwdef` macro to directly create a constructor with keyword and default values. The `rng` we are going to use it the `Xoshiro` which will be seeded at the moment of creation from the default generator (which is task indipendent, so also the rng generated from it is going to be so).

```julia
Base.@kwdef mutable struct PiMCMC <: AbstractMCMC
    id::UUID = uuid4()
    rng::Xoshiro = Xoshiro([rand(UInt64) for _ in 1:5]...)
    state::Vector{Float64}
    checkpoint_file::HDF5.File = h5open("$id.h5", "w")
    save_file::IO = open("$id.csv", "w")
end
```

We may want to define a finalizer for our type, so that the save file is closed on the exit (we are not going to close the checkpoint file since this is usually shared between threads)

```julia
Base.@kwdef mutable struct PiMCMC <: AbstractMCMC
    id::UUID = uuid4()
    rng::Xoshiro = Xoshiro([rand(UInt64) for _ in 1:5]...)
    state::Vector{Float64}
    checkpoint_file::HDF5.File = h5open("$id.h5", "w")
    save_file::IO = open("$id.csv", "w")
	function PiMCMC(id::UUID, rng::Xoshiro, state::Vector{Float64}, checkpoint_file::HDF5.File, save_file::IO)
        x = new(id, rng, state, checkpoint_file, save_file)
        f(t) = close(save_file)
        finalizer(f, x)
    end
end
```

We return `observables` as a method instead:
```julia
observables(::PiMCMC) = [mcmc -> (x, y = state(mcmc); x^2 + y^2 < 1. ? 1 : 0)]
```

## Define the Methods

We also need to define `sample` and `update!` methods. Note that `sample` is used as utility in case of more complicated priors but the returned value is not actually used, for all purposes it can be a NoOp function.

The sample method requires to sample a 2D point uniformily in the $[0, 1]\times [0, 1]$ square
```julia
sample(mcmc::AbstractPiMCMC) = rand(rng(mcmc), 2)
```

The `update!` method takes in input both the `mcmc` and the value returned from `sample`, updates the state of the `mcmc` and returns whether the point has been accepted or not in order to track the acceptance of the chain. In this case the point is always accepted.

```julia
update!(mcmc::AbstractPiMCMC, x_test::Vector{Float64}) = (mcmc.state = x_test; return true)
```

We also define how the state of the chain should be saved on the HDF5 file. In particular we are going to save both the state and the state of the rng so that the computation can be resumed fully.

```julia
function HDF5.write(parent::Union{HDF5.File, HDF5.Group}, group_name::String, mcmc::AbstractPiMCMC)
    group = create_group(parent, group_name)
    group["mcmc_state"] = mcmc.state
    group["rng"] = [mcmc.rng.s0, mcmc.rng.s1, mcmc.rng.s2, mcmc.rng.s3, mcmc.rng.s4]
    flush(group)
end
```
