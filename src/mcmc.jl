"""
	default_save_file([id::UUID])

utility function to create a temporary file for saving the output of the MCMC run.
If a UUID is provided, the file will be named with the UUID. Otherwise, a temporary file
is created.
"""
default_save_file() = (filename = tempname() * ".csv"; @info "saving output in temp file" filename; open(filename, "w"))
default_save_file(id::UUID) = (filename = "$id.csv"; @info "saving output in file" filename; open(filename, "w"))

"""
default_checkpoint_file([id::UUID])

utility function to create a temporary file for saving the checkpoint of the MCMC run.
If a UUID is provided, the file will be named with the UUID. Otherwise, a temporary file
is created.
"""
default_checkpoint_file() = (filename = tempname() * ".h5"; @info "saving checkpoint in temp file" filename; h5open(filename, "w"))
default_checkpoint_file(id::UUID) = (filename = "$id.h5"; @info "saving checkpoint in file" filename; h5open(filename, "w"))

"""
	mcmc_logger([id::UUID], every::Int=100; all::Bool=false)

utility function to create a temporary file for saving the logs of the MCMC run.
The logs are printed every `every` iterations. With `all==false` only the final 
log with the conclusion of the run is printed. The filter is applied only to the
logs of the MCMC module.
"""
function mcmc_logger(every::Int=100; all::Bool=false, filename::String=tempname() * ".log")
    @info "saving log in temp file" filename
    function filter(log)
        log._module == MCMC || return true
        if all || log.id == :MCMC_run_iteration
            return true
        end
        return false
    end
    return EarlyFilteredLogger(filter,
        ActiveFilteredLogger(log -> log._module ≠ MCMC || log.kwargs[:iteration] % every == 0,
            FileLogger(filename))
    )
end
mcmc_logger(id::UUID, every::Int=100; all::Bool=false) = mcmc_logger(every; all=all, filename="$id.log")
