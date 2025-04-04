using Documenter, MCMC

makedocs(
	sitename="MCMC", 
	modules=[MCMC],
	pages = [
		"Home" => "index.md",
		"Documentation" => [
			"Abstract MCMC" => "abstract_mcmc.md",
			"Utilities" => "utils.md",
		]
	],
	)

	deploydocs(; repo="github.com/VinceNeede/MCMC.jl", devbranch="main", push_preview=true)