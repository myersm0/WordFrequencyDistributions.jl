
using WordFrequencyDistributions
using Chain
using StatsBase: quantile
using Pkg.Artifacts

# This set of examples uses a small dataset I made for a topic modeling problem,
# consisting of GPT-4-generated readme docs for 70 hypothetical projects/repos 
# in 7 different categories: web design, space exploration, cooking, etc.

# The methods here are based on those outlined in Baayen 2001 chapter 5, but with
# some modification to handle this particular dataset

rootpath = artifact"medadata"

filelist = [joinpath(rootpath, "$i.readme.md") for i in 1:70]
classes = vcat([repeat([i], 10) for i in 1:7]...)

tokenize(str::String) = @chain split(str, r"[^\w]+") filter(x -> x != "", _)

function process_file(filename)
	@chain filename begin
		readlines
		filter(x -> x != "", _)
		[x |> lowercase |> tokenize for x in _]
		vcat(_...)
		string.(_)
	end
end

docs = process_file.(filelist)

# make a single Corpus from the concatenated documents:
c = Corpus(vcat(docs...))

# The dispersion function measures, for each word in the vocabulary, how much
# that word is present across 40 equally-sized splits (by default) of the Corpus;
# but here, for demonstration purposes, instead of the default we'll split the 
# corpus at document boundaries. Since the documents by design are fairly 
# homogeneous in size, this is not too bad
d0 = dispersion(c; endpoints = cumsum(length.(docs)))

# The result is a 3633 x 70 BitMatrix, where rows represent the vocabulary,
# in the order obtained by `ω(c)`, and columns represent the 70 partitions
# that we specified. Each value represents presense (1) or absence (0) of a word
# in the respective partition.

# In this case, we only want a count of partitions that each word occurs in,
# so we can reduce away the second dimension by summing:
observed_counts = sum(d0; dims = 2)

# For comparison, we could shuffle or permute the corpus 1000 times and each time
# calculate the dispersion (this time across 70 equally-sized partitions) and
# reshape the results into a 3D array:
k = 70
d_perm = @chain begin
	[dispersion(permute(c); k = k) for _ in 1:1000]
	reduce(hcat, _)
	reshape(_, V(c), k, 1000)
end

# for each word w, at each of the 1000 iterations, in how many different partitions
# did that word occur?
permuted_counts = dropdims(sum(d_perm; dims = 2); dims = 2)

# the below will determine the 20% most undersdispersed words in c's vocabulary
# i.e. the words that are the most topical or specialized. Some examples:
# html, css, galaxies, celestial, cuisine, cookbooks
result = map(
	i -> mean(permuted_counts[i, :] .<= observed_counts[i]), 
	1:size(temp, 1)
)
thresh = quantile(result, 0.2)
inds = findall(result .== 0)
ω(c)[inds]


