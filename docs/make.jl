using Documenter, MCMC, HDF5

makedocs(
    sitename="MCMC",
    modules=[MCMC],
    pages=[
        "Home" => "index.md",
        "Documentation" => [
            "Abstract MCMC" => "abstract_mcmc.md",
            "PiMCMC" => "pi_mcmc.md",
            "Utilities" => "utils.md",
        ]
    ],
    checkdocs=:export,
)

deploydocs(; repo="github.com/VinceNeede/MCMC.jl", devbranch="main", push_preview=true)