"""
	AbstractPiMCMC <: AbstractMCMC
	
Abstract type for PiMCMC algorithms. Concrete subtypes must have implemented
either a method for the state and for the random number generator or have
them as fields as `state` and `rng`.
"""
abstract type AbstractPiMCMC <: AbstractMCMC end

"""
	state(mcmc::AbstractPiMCMC)

Returns the state of the MCMC as a field.
"""
state(mcmc::AbstractPiMCMC) = mcmc.state

"""
	rng(mcmc::AbstractPiMCMC)

Returns the random number generator of the MCMC as a field.
"""
rng(mcmc::AbstractPiMCMC) = mcmc.rng

"""
	sample(mcmc::AbstractPiMCMC)
	
Sample a new point in the [0, 1]×[0, 1] square.
"""
sample(mcmc::AbstractPiMCMC) = rand(rng(mcmc), 2)

"""
	update!(mcmc::AbstractPiMCMC, x_test::Vector{Float64})
	
Update the state of the MCMC with the new point, return always true.
"""
update!(mcmc::AbstractPiMCMC, x_test::Vector{Float64}) = (mcmc.state = x_test; return true)

"""
	theta(mcmc::AbstractPiMCMC)
	
Function theta, it returns 1 if the point is inside the unit circle, 0 otherwise.
"""
theta(mcmc::AbstractPiMCMC) = state(mcmc)[1]^2 + state(mcmc)[2]^2 < 1. ? 1 : 0

"""
	observables(mcmc::AbstractPiMCMC)

Returns the observables of the PiMCMC.
"""
observables(::AbstractPiMCMC) = [theta]

"""
	HDF5.write(file::HDF5.File, group_name::String, mcmc::AbstractPiMCMC)

Write the state of the MCMC to the HDF5 file. The concrete type must
have implemented `rng_state` 
"""
function HDF5.write(file::HDF5.File, group_name::String, mcmc::AbstractPiMCMC)
    group = create_group(file, group_name)
    group["mcmc_state"] = mcmc.state
    group["rng"] = rng_state(mcmc)
    flush(group)
end
