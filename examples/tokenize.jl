using WordFrequencyDistributions
using Chain
using StatsBase
using Pkg.Artifacts

## Set up "Alice in Wonderland" text to match results from Baayen 2001

rootpath = artifact"pg_texts"
filename = joinpath(rootpath, "pg11.txt") # Alice in Wonderland

# attempt to tokenize in the exact way Baayen did in the book
lines = readlines(filename)[54:3403]
chapter_starts = findall(occursin.(r"^CHAPTER", lines))
chapter_names = chapter_starts .+ 1
lines = lines[setdiff(1:length(lines), chapter_starts)]

tokenize(str::String) = @chain split(str, r"[^a-z0-9'’-]+") filter(x -> x !=     "", _)

# this comes very close to Baayen's N = 26505, V = 2651:
text = @chain lines begin
	filter(x -> x != "", _)
	[x |> lowercase |> tokenize for x in _]
	vcat(_...)
	string.(_)
	filter(x -> occursin(r"[a-z0-9]", x), _)
end

