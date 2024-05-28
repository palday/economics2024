module Econ2024

using Arrow
using CSV
using DataFrames
using Downloads
using Markdown
using MixedModels
using Scratch
using ZipFile

const CACHE = Ref("")
const MMDS = String[]
const ML_LATEST_URL = "https://files.grouplens.org/datasets/movielens/ml-latest.zip"

_file(x) = joinpath(CACHE[], string(x, ".arrow"))

function __init__()
    CACHE[] = @get_scratch!("data")
    append!(MMDS, MixedModels.datasets())
end

clear_scratchspaces!() = Scratch.clear_scratchspaces!(@__MODULE__)

function extract_csv(zipfile, fname; kwargs...)
    file = only(filter(f -> endswith(f.name, fname), zipfile.files))
    return CSV.read(file, DataFrame; delim=',', header=1, kwargs...)
end

const metadata = Dict{String,String}("url" => ML_LATEST_URL)

function create_arrow(fname, df)
    arrowfile = _file(splitext(basename(fname))[1])
    Arrow.write(arrowfile, df; compress=:lz4, metadata)
    return arrowfile
end

const GENRES = ["Action", "Adventure", "Animation",
                "Children", "Comedy", "Crime",
                "Documentary", "Drama",
                "Fantasy", "Film-Noir",
                "Horror",
                "IMAX",
                "Musical", "Mystery",
                "Romance",
                "Sci-Fi",
                "Thriller",
                "War", "Western"]

function _genre(::Missing)
    vals = Tuple(false for _ in GENRES)
    keys = Tuple(Symbol(replace(g, "-" => "_")) for g in GENRES)
    return NamedTuple{keys}(vals)
end

function _genre(x)
    vals = Tuple(occursin(g, x) for g in GENRES)
    keys = Tuple(Symbol(replace(g, "-" => "_")) for g in GENRES)
    return NamedTuple{keys}(vals)
end

function movielens_download()
    @info "Downloading data"
    quiver = String[]
    open(Downloads.download(ML_LATEST_URL), "r") do io
        zipfile = ZipFile.Reader(io)
        @info "Extracting and saving ratings"
        ratings = extract_csv(zipfile, "ratings.csv";
            types=[Int32, Int32, Float32, Int32],
            pool=[false, false, true, false],
        )
        push!(quiver, create_arrow("ratings.csv", ratings))
        @info "Extracting movies that are in the ratings table"
        movies = leftjoin!(
            leftjoin!(
                sort!(combine(groupby(ratings, :movieId), nrow => :nrtngs), :nrtngs),
                extract_csv(zipfile, "movies.csv"; types=[Int32,String,String], pool=false);
                on=:movieId,
            ),
            extract_csv(zipfile, "links.csv"; types=[Int32,Int32,Int32]);
            on=:movieId,
        )
        disallowmissing!(movies; error=false)
        movies.nrtngs = Int32.(movies.nrtngs)
        transform!(movies, :genres => ByRow(_genre) => AsTable)
        select!(movies, Not("genres"))  # now drop the original genres column
        push!(quiver, create_arrow("movies.csv", movies))
        @info "Extracting and saving README"
        readme = only(filter(f -> endswith(f.name, "README.txt"), zipfile.files))
        open(joinpath(CACHE[], "README.txt"), "w") do io
            write(io, read(readme))
        end

        # select!(movies, Not([:genres, :title]))
        select!(ratings, Not(:timestamp))
        leftjoin!(ratings, movies; on=:movieId)
        disallowmissing!(ratings, replace.(Econ2024.GENRES, "-" => "_"))
        select!(ratings, Not(["nrtngs", "imdbId", "tmdbId"]))
        disallowmissing!(ratings)
        create_arrow("ratings_genre", ratings)

        return nothing
    end

    return quiver
end

const OSF_IO_URIs = Dict{String,String}(
    "box" => "tkxnh",
    "elstongrizzle" => "5vrbw",
    "oxboys" => "cz6g3",
    "sizespeed" => "kazgm",
    "ELP_ldt_item" => "c6gxd",
    "ELP_ldt_subj" => "rqenu",
    "ELP_ldt_trial" => "3evhy",
    "movies" => "kvdch",
    "ratings" => "v73ym",
)

function osf_io_dataset(name::AbstractString)
    if haskey(OSF_IO_URIs, name)
        Downloads.download(
            string("https://osf.io/", OSF_IO_URIs[name], "/download"),
            _file(name),
        )
        return true
    end
    return false
end

dataset(name::Symbol) = dataset(string(name))
function dataset(name::AbstractString)
    name in MMDS && return MixedModels.dataset(name)
    f = _file(name)
    isfile(f) || osf_io_dataset(name) ||
        throw(ArgumentError("$(name) is not a dataset "))
    return Arrow.Table(f)
end

"""
    movielens_readme()

Show the MovieLens data readme.

"""
function movielens_readme()
    return Markdown.parse_file(joinpath(CACHE[], "README.txt"))
end

end # module
