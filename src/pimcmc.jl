"""
	AbstractPiMCMC <: AbstractBaseMCMC{Vector{Float64}}
	
Alias for `AbstractBaseMCMC{Vector{Float64}}`. Used for algorithms that compute π.
"""
abstract type AbstractPiMCMC <: AbstractBaseMCMC{Vector{Float64}} end

"""
	sample(mcmc::AbstractPiMCMC)
	
Sample a new point in the [0, 1]×[0, 1] square.
"""
sample(mcmc::AbstractPiMCMC) = rand(rng(mcmc), 2)

"""
	update!(mcmc::AbstractPiMCMC, x_test::Vector{Float64})
	
Update the state of the MCMC with the new point, return always true.
"""
update!(mcmc::AbstractPiMCMC, x_test::Vector{Float64}) = (mcmc.state .= x_test; return true)

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
	PiMCMC <: AbstractPiMCMC

Concrete type for PiMCMC algorithms. 
"""
@BaseMCMC_def Vector{Float64} struct PiMCMC <: AbstractPiMCMC end
