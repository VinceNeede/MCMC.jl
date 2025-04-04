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
	mcmc_logger(every::Int=100)

utility function to create a temporary file for saving the logs of the MCMC run.
The logs are printed every `every` iterations.
"""
function mcmc_logger(every::Int=100)
	filename = tempname() * ".log"
	@info "saving log in temp file" filename
	function filter(log)
		if log._module == MCMC && log._id == :MCMC_run_iteration
			return true
		end
		return false
	end
	return ActiveFilteredLogger(log -> log.iteration % every == 0, EarlyFilteredLogger(filter, FileLogger(filename)))
end
