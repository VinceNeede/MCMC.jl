default_save_file() = (filename = tempname() * ".csv"; @info "saving output in temp file" filename; open(filename, "w"))
default_checkpoint_file() = (filename = tempname() * ".h5"; @info "saving checkpoint in temp file" filename; filename)
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
