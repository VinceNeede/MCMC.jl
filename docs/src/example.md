# Usage Example

The library `MCMC.jl` aims to be thread safe, so that more chains can be started in parallel.

We first need to import both the `MCMC` and `HDF5` libraries, and the `Semaphore` symbol and methods from `Base`.
```julia
import Base: Semaphore, acquire, release

using MCMC, HDF5
```

The `Semaphore` allows us to specify how many tasks can run in parallel. In this example we will set it equal to the number of threads with which julia has been started

```julia
const semaphore = Semaphore(Threads.nthreads())
```

We now overload the method `MCMC.should_save` to set the frequency with which the state of the computation should be saved.

```julia
MCMC.should_save(::PiMCMC, i::Int) = i % 1_000 == 0
```

We now define our `main` function. This will increment the semaphore, create a new `PiMCMC` object and start the run. At the end we release the semaphore so that another task can start. We also use a `try-finally` block to ensure the file is properly closed in case an error occurs
```julia
function main(file::HDF5.File)

    acquire(semaphore)

    pi_mcmc = PiMCMC([0.0, 0.0], checkpoint_file=file)

    Base.with_logger(mcmc_logger(id(pi_mcmc), 1_000)) do
        try
            run!(pi_mcmc, 1_000_000)  # Ensure this does not yield
        finally
            close(save_file(pi_mcmc))
        end
    end

    release(semaphore)
end
```

We now start the computation creating a file `checkpoint.h5` and scheduling the tasks

```julia
h5open("checkpoint.h5", "w") do file
    tasks = [Threads.@spawn main($file) for _ in 1:10]
    wait.(tasks)
end
```

All the files will be saved in the local folder as `CSV` files. 
We can then unify the data in a seperated session. First define an utility function to get the files:
```julia
function get_res(; path::String=".")
    dir = readdir(path)
    files = filter(x -> (isfile(x) && endswith(x, ".csv")), dir)
    return files
end

files = get_res()
```
We now import `CSV` tor ead the files and `Statistics` to analyze them
```julia
using CSV, Statistics
```
After that, we read each data file and append the data to a vector
```julia
all_data = Float64[]

for file in files
    data = CSV.File(file, header=false)["Column1"]
    append!(all_data, data)
end
```

We can now compute the mean and the standard deviation over the combined data
```julia
@show 4 * mean(all_data) 4 * std(all_data) / sqrt(length(all_data))
```