"""
	PiMCMC <: AbstractPiMCMC <: AbstractMCMC

Concrete type for PiMCMC algorithms. 

The rng is a Xoshiro, by default it seeded with the default generator.

The checkpoint_file is defaulted using [`default_checkpoint_file`](@ref default_checkpoint_file).

The save_file is defaulted using [`default_save_file`](@ref default_save_file).

The closing of the file is automatically handled by the finalizer.

The `rng_state` method is implemented for the type, but not the `should_save`.
"""
Base.@kwdef mutable struct PiMCMC <: AbstractPiMCMC
    rng::Xoshiro = Xoshiro([rand(UInt64) for _ in 1:5]...)
    state::Vector{Float64}
    checkpoint_file::String = default_checkpoint_file()
    save_file::IO = default_save_file()
    function PiMCMC(rng::Xoshiro, state::Vector{Float64}, checkpoint_file::String, save_file::IO)
        x = new(rng, state, checkpoint_file, save_file)
        f(t) = (@async println("Finalizing $t."); close(save_file))
        finalizer(f, x)
    end
end

"""
	rng_state(mcmc::PiMCMC)

Returns the state of the `Xoshiro` rng as a vector.
"""
rng_state(mcmc::PiMCMC) = [mcmc.rng.s0, mcmc.rng.s1, mcmc.rng.s2, mcmc.rng.s3, mcmc.rng.s4]
