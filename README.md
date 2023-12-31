# WordFrequencyDistributions
A Julia implementation of some of the techniques for estimating and analyzing word frequency statistics, from R. Harald Baayen's book _Word Frequency Distributions_ (Springer, 2001).

Operations center around the `Corpus` struct, which was designed to provide excellent performance over a range of operations that the book discusses. A `Corpus` is both very fast and memory-efficient; even after initializing auxiliary fields, its RAM usage tends to be about the same as that of the original text vector it was constructed from.

A `Corpus` may be a single text (the text of a novel, for example) or a collection of documents. However, in either case, the words are simply stored as a single homogenous entity, and the document divisions (if any) are not recoverable or of interest.

Function and field names were chosen as a compromise between fidelity to Baayen's notation in the book, and the goal of having a nice, consistent interface to all the functions. The main exception is where the book names something like `V(N)` (where N is the number of tokens in a corpus); in this package, I implement that as `V(c::Corpus)`, where the corpus `c` encapsulates `N`, among other things. Also, I apologize for having violated style conventions by using capitals for some function names (V, N, etc), but otherwise I would have had to impose a very different naming scheme of my own invention, and that seemed contrary to my goals here. So, functions in this package are designed to resemble formulae from the book as much as possible.

Another deviation from Baayen's notation is in cases where he names things such as the "characteristic constants" Yule's _K_, Simpson's _D_, Zipf size _Z_, etc. I've instead named these functions all `C` for characteristic constant and provided trait-based dispatch to distinguish them, such as `C(::Yule, args...)` and `C(::Simpson, args...)`, etc, to emphasize their similar nature and to reduce the alphabet-soup aspect of the interface somewhat.

An example application is given in `examples/lexical_specialization.jl`, where I show how these concepts could be used to evaluate document clusters from an unsupervised topic modeling scheme.

## Usage
If you have a vector of strings called `text` (e.g. tokenized from a document), constructing a `Corpus` struct is simple:
```
c = Corpus(text)
```

To evaluate statistics on a smaller sample, such as on the first 1000 words of `c`, you would subset your corpus like this:
```
smaller_corpus = c[1:1000]
V(smaller_corpus) # get the size of the vocabulary in the reduced corpus
N(smaller_corpus) # the total number of words in the reduced corpus (1000)
```

You can also sample or permute a corpus. The difference is only one of notation; `permute` here is just a complete reordering of the word occurrences. These two operations are the same:
```
sampled_corpus = sample(c, 1:N(c); replace = false)
permuted_corpus = permute(c)
```

For sample and population statistics relating to your corpus, the general pattern of functions offered is as follows: `𝑓([::Estimator,] args...; kwargs...)`. If you omit the first argument, an `Estimator`, then the operation is performed empirically on the observed sample. Otherwise, you may supply an `Estimator` for which an estimation method is defined. Here are a few different ways to compute the number of distinct tokens (types) that occur exactly once in a corpus `c`.
```
# actual number of words in the observed sample that occur exactly once:
V(1, c)

# Gale and Sampson's Zipfian smoother to derive a theoretical value of V(1, c):
V(GaleSampson(), 1, c)

# binomial interpolation for the expected value of V(1, c) in a smaller corpus 
# of 10,602 tokens:
V(BinomialExpectation(), 1, c; n = 10602)
```

A couple of loss functions are implemented, which you can use like this:
```
# set up a couple of higher-order functions which we'll compare below:
observed = m, c -> V(m, c)
estimated = m, c -> V(BinomialExpectation(), m, c; n = 10602)

# calculate the MSE of using the binomial expectation of V(m, c) relative to
# the actual observed value, over the range of spectrum elements 1 through 15:
loss(MSE(), c; y = observed, yhat = estimated, spectra = 1:15)

# as above, but use the relative MSE variant, "MSEr" (equation 3.2 from Baayen):
loss(MSEr(), c; y = observed, yhat = estimated, spectra = 1:15)
```

Below I demonstrate creation of a figure similar to one that Baayen shows in Chapter 1. Here we are using the relative sample frequency `p` of the word "the" in the text, as observed in 20 intervals of increasing size, along with Monte Carlo 95% confidence bounds (shown by dotted lines) generated from 5000 random permutations of the text:
```
using GLMakie
using StatsBase: quantile

w = "the"

nsteps = 20
break_pts = intervals(c; nsteps = nsteps)
observed_p = map(N -> p(c[w][1:N]), break_pts)

ntrials = 1000
permuted_p = zeros(nsteps, ntrials)
for i in 1:ntrials
    temp = sample(c[w], N(c); replace = false)
    permuted_p[:, i] .= [p(temp[1:N]) for N in break_pts]]
end

conf_intervals = map(x -> quantile(x, (0.025, 0.975)), eachrow(permuted_p))

fig = Figure()
ax = Axis(fig[1, 1])
scatter!(ax, break_pts, observed_p; color = :black)
lines!(ax, break_pts, first.(conf_intervals); color = :black, linestyle = :dot)
lines!(ax, break_pts, last.(conf_intervals); color = :black, linestyle = :dot)
```
![demo1](https://github.com/myersm0/WordFrequencyDistributions.jl/blob/main/examples/demo1.png)

In this example we're only interested in one word, "the". But the main advantage of this package comes when you have a larger set of words that are of interest, or if you want do something with occurrence counts from the whole vocabulary. 

For example, the function call `V(1, c)` supplied by this package is more than 10x faster than doing the equivalent operation on a `Vector{String} text`:
```
V(1, c)                           #  750 ns (on first execution; faster after that)
sum(values(countmap(text)) .== 1) # 8174 ns
```

Not only that, but calling `V(1, c)` (or similar) caches the results for the whole frequency spectrum so that later calls reduce to ~30 ns:
```
V(2, c)     # 27 ns; the number of words occurring 2 times
V(999, c)   # 33 ns; the number of words occurring 999 times
spectrum(c) # accessor for the whole frequency spectrum V(m, c)
```

## Performance notes and comparison to ZipfR
There's already an excellent package in the R language for the things implemented here (and more), [zipfR](http://zipfr.r-forge.r-project.org). With the current package, I wanted to see if I could improve on the performance in terms of both speed and capacity for handling large corpora.

I found two things. One, the performance of zipfR is already excellent. Two, it's hard to compare the two packages directly, because they operate very differently and because use cases can differ so much. For example:
- for initialization of a corpus of 27k tokens, I get a 1.97 ms initialization time in this package, compared to 6.16 ms with zipfR. For larger corpora however, zipfR comes out ahead
- this package comes out ahead in subsetting and sampling operations (e.g. for subsetting and computing occurrence statistics for the first 1000 tokens of `c`, I get 31 μs in this package versus 588 μs in zipfR; performance gains in this respect are similar for random sampling and for larger sizes)

The reasons for the performance difference behind both of these examples is the same: this package does more work upfront in constructing the corpus, in order to facilite fast subsetting and sampling later on.

[![Build Status](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml?query=branch%3Amain)

