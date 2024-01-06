
using WordFrequencyDistributions
using Chain
using StatsBase: quantile
using Pkg.Artifacts
using GLMakie
using Colors

# This set of examples uses a small dataset I made for a topic modeling problem,
# consisting of GPT-4-generated readme docs for 70 hypothetical projects/repos 
# in 7 different categories: web design, space exploration, cooking, etc.

# first set up the data:
rootpath = artifact"medadata"
filelist = [joinpath(rootpath, "$i.readme.md") for i in 1:70]

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


# ===== Part 1: Vocabulary dispersion ==========================================
# The methods here are based on those outlined in Baayen 2001 chapter 5, 
# but with some modification to handle this particular dataset

# make a single Corpus from the concatenated documents:
c = Corpus(vcat(docs...))

# The dispersion function measures, for each word in the vocabulary, how often
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
	1:size(permuted_counts, 1)
)
thresh = quantile(result, 0.2)
inds = findall(result .== 0)
ω(c)[inds]


# ===== Part 2: Vocabulary growth within a particular topic ====================

# number the topics 1 through 7; they're in order, with 10 docs per topic
classes = vcat([repeat([i], 10) for i in 1:7]...)

# pick out a particular topic to look at, say the first one:
class = 1
docs_in_class = docs[classes .== class]
docs_out_of_class = setdiff(docs, docs_in_class)

# make a corpus just from that topic:
c = Corpus(vcat(docs_in_class...))

# get 20 equispaced points
endpoints = intervals(c)

# measure the vocabulary size V in increasing steps up to N(c)
v = [V(c[1:t]) for t in endpoints]

# measure the expected vocabulary size E(V) over the same intervals,
# conditioned on the whole within-topic corpus but interpolated to timepoint t
# with binomial expected value (Baayen equation 2.42)
ev = [V(BinomialExpectation(), c; t = t) for t in endpoints]

fig = Figure()
ax = Axis(fig[1, 1])
lines!(ax, endpoints, v; color = :black, linewidth = 5)
lines!(ax, endpoints, ev; color = :black, linewidth = 5, linestyle = :dot)

# now do an experiment where we repeatedly substitute the last in-topic document with
# one of the out-of-class docs and see how that changes the tail-end of the observed
# vocabulary size as well as the whole curve of expected values
for doc in docs_out_of_class
	temp_docs = docs_in_class[1:(end - 1)]
	push!(temp_docs, doc)
	c′ = Corpus(vcat(temp_docs...))
	local endpoints = intervals(c′)
	local v = [V(c′[1:t]) for t in endpoints]
	local ev = [V(BinomialExpectation(), c′; t = t) for t in endpoints]
	lines!(ax, endpoints, v; color = RGBA(1, 0.5, 0, 0.1))
	lines!(ax, endpoints, ev; color = RGBA(1, 0.5, 0, 0.1), linestyle = :dot)
end

# you could also look at the curve of the growth rate P (Baayen section 2.5):
growth_rate = [P(BinomialExpectation(), c; t = t) for t in endpoints]

# or the coefficient of loss (Baayen 2.27):
l = CL(c)

# we might expect both of these values to be higher when mixing in out-of-class douments


