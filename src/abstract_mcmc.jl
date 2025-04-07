"""
	AbstractMCMC

Supertype for all MCMC algorithms. It provides a common interface 
for sampling, updating, and saving the MCMC state.

All subtypes of `AbstractMCMC` should implement the following methods:
- `sample(<:AbstractMCMC)`: Sample a new point from the proposal distribution.
- `update!(<:AbstractMCMC, x_test)`: Update the MCMC state with the new point. It should return
true if the configuration has been modified, and false otherwise.


Optionally subtypes of `AbstractMCMC` can overload the function `should_save` to define
when the MCMC state should be saved. By default, the state will never be saved. In order
to save the state, the method `HDF5.write(::HDF5.File, ::String, <:AbstractMCMC)` must be defined.

Furthermore the following symbols should be defined for the subtype either as fields or as methods:
- `rng(<:AbstractMCMC)`: Return the random number generator to be used for sampling. 
- `observables(<:AbstractMCMC)`: Return a list of observables to be computed, 
observables must be functions that take the mcmc as argument.
- `save_file(<:AbstractMCMC)`: Return an IO stream where the the obervables output will be saved.
- `checkpoint_file(<:AbstractMCMC)`: Return the filename to save the MCMC state. Alternatively, 
a checkpoint_file field can be defined for the subtype.
"""
abstract type AbstractMCMC end

for fun in [:checkpoint_file, :save_file, :rng, :observables]
    @eval begin
        """
        	$($(fun))(mcmc::AbstractMCMC)

        If the concrete subtype of `AbstractMCMC` has $($(fun)) as a field, it will be returned,
        otherwise a `MethodError` will be thrown. 
        """
        function $(fun)(mcmc::AbstractMCMC)
            if hasfield(typeof(mcmc), $(QuoteNode(fun)))
                return getfield(mcmc, $(QuoteNode(fun)))
            else
                throw(MethodError($fun, (typeof(mcmc),)))
            end
        end
    end
end

"""
	should_save(mcmc::AbstractMCMC, i::Int)

Determine if the MCMC state should be saved. By default, it returns false.
Subtypes of `AbstractMCMC` can overload this function to define when the state
should be saved. The default implementation is to never save the state.
"""
should_save(mcmc::AbstractMCMC, ::Int) = false

"""
	save!(mcmc::AbstractMCMC, iter::Int)

Save the MCMC state to the checkpoint HDF5 file calling `HDF5.write`.
"""
function save!(mcmc::AbstractMCMC, iter::Int)
    filename = checkpoint_file(mcmc)
    h5open(filename, "cw") do file
        ishdf5(filename) || throw(ArgumentError("checkpoint_file must be a valid HDF5 file. $filename"))
        # Save the MCMC state to the HDF5 file
        key = "$(typeof(mcmc))" * "_state"
        haskey(file, key) && delete_object(file, key)
        HDF5.write(file, key, mcmc)
        file[key]["iteration"] = iter
    end
end


"""
	run!(mcmc::AbstractMCMC, n::Int; every::Int=1)

Run the MCMC algorithm for `n` iterations. It will sample a new point, update the configuration,
compute the observables and save the state when `should_save` returns true.

The keyword `every` can be used to set 

The steps are logged at debug level. For utility you can use the [`mcmc_logger`](@ref mcmc_logger) function to:
```julia
with_logger(mcmc_logger()) do
	run!(mcmc, n)
end
```
"""
function run!(mcmc::AbstractMCMC, n::Int; every::Int=1)
    accepted = 0
    out_io = save_file(mcmc)::IOStream
    try
        for i in 1:n
            @debug "sampling new point" _id = :MCMC_run_sample_step iteration = i
            x_test = sample(mcmc)

            @debug "updating configuration" _id = :MCMC_run_update_config iteration = i
            update!(mcmc, x_test) && (accepted += 1)

            if should_save(mcmc, i)
                @debug "saving configuration" _id = :MCMC_run_save_config iteration = i
                save!(mcmc, i)
            end

            if i % every == 0
                @debug "computing observables" _id = :MCMC_run_observable iteration = i
                result = [obs(mcmc) for obs in observables(mcmc)]
                println(out_io, join(result, ", "))
            end

            @debug "Iteration $i completed" acceptance = accepted / i _id = :MCMC_run_iteration iteration = i
        end
    finally
        close(out_io)
    end
end