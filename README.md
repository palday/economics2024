# Mixed Models in Julia

This repository uses [Quarto](https://quarto.org) with the Julia code execution supplied by [QuartoNotebookRunner.jl](https://github.com/PumasAI/QuartoNotebookRunner.jl/), which requires Quarto 1.5+.

As of early May 2024, Quarto 1.5 is only available as a preview release, which you'll need to [download from GitHub](https://github.com/quarto-dev/quarto-cli/releases). Under each release's "Assets", you can find platform-specific installers.

```sh
~/economics2024$ julia

julia> using Pkg

julia> Pkg.activate(".")
  Activating project at `~/economics2024`

julia> Pkg.instantiate()
< lots of output >

julia> exit()

~/economics2024$ quarto preview

< lots of output >
```

## The MovieLens Data

A number of sample datasets from the book [Embrace Uncertainty]() are downloaded on demand for examples. The MovieLens data in particular is downloaded as needed from the MovieLens repository due to [restrictions on separate distribution](https://files.grouplens.org/datasets/movielens/ml-25m-README.html). The data is used only for education purposes and must not be used for commercial purposes.
