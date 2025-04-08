"""
	AbstractBaseMCMC{T} <: AbstractMCMC
Base abstract class for MCMC algorithms.
The type parameter `T` is the type of the state of the MCMC.
Concrete subtypes are required to have the following fields:

- `id::UUID`: Unique identifier for the MCMC instance.
- `rng::Xoshiro`: Random number generator, default is seeded with the default generator.
- `state::T`: The state of the MCMC, type `T` is the type of the state.
- `checkpoint_file::HDF5.File`: File for checkpointing, default is created using `default_checkpoint_file`.
- `save_file::IO`: File for saving the MCMC state, default is created using `default_save_file`.

Also, the type `T` must have implemented the method `HDF5.write`

The default constructor is provided:
```julia
	BaseMCMC_T(state::T; id::UUID=uuid4(), rng::Xoshiro=Xoshiro([rand(UInt64) for _ in 1:5]...),
		checkpoint_file::HDF5.File=default_checkpoint_file(id), save_file_::IO=default_save_file(id))
```
"""
abstract type AbstractBaseMCMC{T} <: AbstractMCMC end

"""
	@BaseMCMC_def(T, expr)
Macro to define a keyword constructor for `AbstractBaseMCMC{T}` concrete subtypes.
The symbol `T` is the type of the state of the MCMC.

If other fields are defined in the struct, they will be preserved. Mind that in this case
the keyword constructor will fail, so you will have to define it manually.

```julia
@macroexpand @BaseMCMC_def Vector{Float64} struct PiMCMC <: AbstractPiMCMC end

# output

:(struct PiMCMC <: Main.AbstractPiMCMC
      #= /tmp/jl_6fDa5dH.jl:7 =#
      id::Main.UUID
      #= /tmp/jl_6fDa5dH.jl:8 =#
      rng::Main.Xoshiro
      #= /tmp/jl_6fDa5dH.jl:9 =#
      state::Main.Vector{Main.Float64}
      #= /tmp/jl_6fDa5dH.jl:10 =#
      checkpoint_file::(Main.HDF5).File
      #= /tmp/jl_6fDa5dH.jl:11 =#
      save_file::Main.IO
      #= /tmp/jl_6fDa5dH.jl:17 =#
  end)

```
"""
macro BaseMCMC_def(T, expr)
    T isa Symbol || Base.isexpr(T, :curly) || error("Invalid type for T")
    Base.isexpr(expr, :struct) || error("@BaseMCMC_def requires a struct as expression")
    old_block = expr.args[3]
    # XXX: Could it be possible to compose it with kwdef?
    new_block = quote
        id::UUID
        rng::Xoshiro
        state::$T
        checkpoint_file::HDF5.File
        save_file::IO
    end
    expr.args[3] = Expr(:block, new_block.args..., old_block.args...)
    return expr
end

"""
	BaseMCMC_T(state::T; id::UUID=uuid4(), rng::Xoshiro=Xoshiro([rand(UInt64) for _ in 1:5]...),
		checkpoint_file::HDF5.File=default_checkpoint_file(id), save_file_::IO=default_save_file(id))

Keyword constructor for `AbstractBaseMCMC{T}` subtypes.
"""
function (::Type{BaseMCMC_T})(state::T; id::UUID=uuid4(), rng::Xoshiro=Xoshiro([rand(UInt64) for _ in 1:5]...),
    checkpoint_file::HDF5.File=default_checkpoint_file(id), save_file_::IO=default_save_file(id)) where {T,BaseMCMC_T<:AbstractBaseMCMC{T}}
    try
        return BaseMCMC_T{T}(id, rng, state, checkpoint_file, save_file_)
    catch e
        if isa(e, TypeError)
            return BaseMCMC_T(id, rng, state, checkpoint_file, save_file_)
        else
            rethrow(e)
        end
    end
end

"""
	rng_state(mcmc::AbstractBaseMCMC)
Return the state of the Xoshiro rng used by the MCMC.
"""
rng_state(mcmc::AbstractBaseMCMC) = [mcmc.rng.s0, mcmc.rng.s1, mcmc.rng.s2, mcmc.rng.s3, mcmc.rng.s4]

"""
	state(mcmc::AbstractBaseMCMC)
Return the state of the MCMC.
"""
state(mcmc::AbstractBaseMCMC) = mcmc.state

"""
	HDF5.write(parent::Union{HDF5.File,HDF5.Group}, group_name::String, mcmc::AbstractBaseMCMC)
Write the MCMC state to the HDF5 file. The state type must implement the `HDF5.write` method.
"""
function HDF5.write(parent::Union{HDF5.File,HDF5.Group}, group_name::String, mcmc::AbstractBaseMCMC)
    group = create_group(parent, group_name)
    try
        HDF5.write(group, "mcmc_state", state(mcmc))
        group["rng"] = rng_state(mcmc)
    finally
        close(group)
    end
end