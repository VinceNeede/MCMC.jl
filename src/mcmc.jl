"""
	default_save_file()

utility function to create a temporary file for saving the output of the MCMC run.
"""
default_save_file() = (filename = tempname() * ".csv"; @info "saving output in temp file" filename; open(filename, "w"))

"""
	default_checkpoint_file()

utility function to create a temporary file for saving the checkpoint of the MCMC run.
"""
default_checkpoint_file() = (filename = tempname() * ".h5"; @info "saving checkpoint in temp file" filename; filename)

"""
	mcmc_logger(every::Int=100; all::Bool=false)

utility function to create a temporary file for saving the logs of the MCMC run.
The logs are printed every `every` iterations. With `all==false` only the final 
log with the conclusion of the run is printed.
"""
function mcmc_logger(every::Int=100; all::Bool=false)
    filename = tempname() * ".log"
    @info "saving log in temp file" filename
    function filter(log)
        log._module == MCMC || return true
        if all || log.id == :MCMC_run_iteration
            return true
        end
        return false
    end
    return EarlyFilteredLogger(filter, ActiveFilteredLogger(log -> log.kwargs[:iteration] % every == 0, FileLogger(filename)))
end
