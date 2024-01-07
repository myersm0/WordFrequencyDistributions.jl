
using WordFrequencyDistributions
using GLMakie

# this will tokenize the text of Alice in Wonderland; by the way, there are probably
# better ways to do it, but I've done it this way to try to figure out and replicate
# the method Baayen used in his book. I wasn't completely successful in that though,
# but close
include(joinpath(dirname(@__FILE__), "tokenize.jl"))

# from the above, we now have a Vector{String} called text in our environment

# initializing a Corpus is fast; most fields are not initialized until they're needed
c = Corpus{Int}(text)

# a count of tokens:
N(c)

# a count of distinct words (types):
V(c)

# to get the distinct words (types):
ω(c)

# say we're interested in a particular word, "the" ...
w = "the"

# get the observed sample frequency of this word in `c`
f(w, c)

# a very related operation is getting the relative sample frequency of that word:
@assert p(w, c) == f(w, c) / N(c)

# to get the relative sample frequencies from a smaller part of the corpus only,
# say the first 1000 words, there are two main ways you could do it:
a = p(w, c[1:1000]) # method 1
b = p(c[w][1:1000]) # method 2
@assert a == b

# In method 1, `c[1:1000]` creates a new corpus, which has some lazily initialized 
# fields. When the `p` function then assesses occurrence counts within `c[1:1000]`,
# this causes some of the lazy fields to be initialized, which is fast but it does
# have some cost to it.
#
# Method 2 is cheaper: first we pull out the occurrence vector of word `w` by 
# `c[w]`, and then we subset just that vector to include the first 1000 elements.
# This neither initializes a new struct nor incurs any cost in computing occurrences
# of words other than the target word `w`.
#
# Therefore method 1 would be preferred only if you have a larger set of words of
# interest, or if you're going to need frequency stats over the whole vocabulary.

# You could get the relative sample frequencies at once for the whole vocabulary:
f(c) / N(c)

# however, that just gives you counts and doesn't tell you what words they 
# correspond to; to get that, you need ω(c), or you could put a Dict together:
Dict(word => freq / N(c) for (word, freq) in zip(ω(c), f(c)))


## now that the basic usage has been illustrated, we'll approximately reproduce
# figure 1.2 from Baayen to demonstrate the non-random distribution of "the"
# in Alice in Wonderland; approximately because the tokenization is not identical

k = 20 # we'll measure at this many equally spaced intervals
ntrials = 1000 # number of Monte Carlo iterations

endpoints = intervals(c; k = k) # 20 equispaced intervals

observed_p = [p(w, c[1:t]) for t in endpoints]

permuted_p = zeros(k, ntrials)
@time for i in 1:ntrials
	c′ = permute(c)
	occurrences = c′[w]
	permuted_p[:, i] .= [p(occurrences[1:t]) for t in endpoints]
end

conf_intervals = map(x -> quantile(x, (0.025, 0.975)), eachrow(permuted_p))

fig = Figure()
ax = Axis(fig[1, 1])
scatter!(ax, endpoints, observed_p; color = :black)
lines!(ax, endpoints, first.(conf_intervals); color = :black, linestyle = :dot)
lines!(ax, endpoints, last.(conf_intervals); color = :black, linestyle = :dot)

# Note that this whole experiment could have been done easily without the help of this
# package. For example, simply working with the original Vector{String} called `text`,
# you could replace lines 58 through 62 with the following:
for i in 1:ntrials
	text′ = sample(text, length(text); replace = false)
	occurrences = text .== w
	permuted_p[:, i] .= [sum(occurrences[1:t]) / t for t in endpoints]
end

# The Vector{String} approach with `text` times at 347 milliseconds on my laptop;
# the Corpus-based approach from lines 15 through 20 times at 196 milliseconds.
# While that 77% speed improvement is nice, this use case doesn't really show
# off the advantages of this package, which mostly come into play when
# you're interested in a large set of words, rather than just one ("the"), 
# or the distributional patterns of the entire vocabulary


𝑓(params) = loss(
	MSE(), c;
	y = (m, c) -> V(m, c),
	yhat = (m, c) -> V(NaranBalasub(), m, c; C = params[1], μ = params[2], γ = params[3]),
	spectra = 1:15
)

struct MySimplexer <: Optim.Simplexer end
optimize(myfun, [0.0, 0.0, 0.0], NelderMead(initial_simplex = MySimplexer()))
Optim.simplexer(S::MySimplexer, initial_C) = [rand(length(initial_C)) for i = 1:length(initial_C) + 1]




ys = [V(NaranBalasub(), m, c; C = 1429.068, μ = 0.193, γ = 1.629) for m in 1:15]
yhats = [V(m, c) for m in 1:15]





