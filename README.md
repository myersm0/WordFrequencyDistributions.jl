# WordFrequencyDistributions
A Julia implementation of some of the techniques for estimating and analyzing word frequency statistics, from R. Harald Baayen's book _Word Frequency Distributions_ (Springer, 1996).

Operations center around the `Corpus` struct, which was designed to provide excellent performance over a range of operations that the book discusses.

A `Corpus` may be a single text (the text of a novel, for example) or a collection of documents. However, in either case, the words are simply stored as a single homogenous entity, and the document divisions (if any) are not recoverable or of interest.

Function and field names were chosen as a compromise between fidelity to Baayen's notation in the book, and the goal of having a nice, consistent interface to all the functions. The main exception is where the book names something like `V(N)` (the size of the vocabulary in a corpus of N words); in this package, I implement that as `V(c::Corpus)`, where the corpus `c` encapsulates `N`, among other things. To evaluate `V()` on a smaller sample, such as on the first 1000 words of `c`, you would subset your corpus like this:
```
smaller_corpus = c[1:1000]
V(smaller_corpus)
```

## Usage
If you have a vector of strings called `text` (e.g. tokenized from a document), constructing a `Corpus` struct is simple:
```
c = Corpus(text)
```

Internally, a `Corpus` stores its data as `UInt32`s by default, which has a range of up to about 4 billion. If you need to store more than 4 billion tokens, you could parametrize the initialization like `Corpus{Int64}(text)`.

For sample and population statistics relating to your corpus, the general pattern of functions offered is as follows: `𝑓([::Estimator,] args...; kwargs...)`. If you omit the first argument, an `Estimator`, then the operation is performed empirically on the observed sample. Otherwise, you may supply an `Estimator` for which an estimation method is defined. Here are a few different ways to compute the number of distinct tokens (types) that occur exactly once in a corpus `c`.
```
# actual value in the observed sample:
V(1, c)

# Gale and Sampson's Zipfian smoother to derive a theoretical value of V(1, c):
V(GaleSampson(), 1, c)

# binomial estimate for the expected value of V(1, c):
V(BinomialEstimator(), 1, c)
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
    c′ = permute(c)
    permuted_p[:, i] .= [p(c′[w][1:N]) for N in break_pts]
end

conf_intervals = map(x -> quantile(x, (0.025, 0.975)), eachrow(permuted_p))

fig = Figure()
ax = Axis(fig[1, 1])
scatter!(ax, break_pts, observed_p; color = :black)
lines!(ax, break_pts, first.(conf_intervals); color = :black, linestyle = :dot)
lines!(ax, break_pts, last.(conf_intervals); color = :black, linestyle = :dot)
```

This actually is not the most efficient way to do this, however, mainly because the line `c′ = permute(c)`, though it's quite fast at what it does, is doing some extra work such as setting up occurrence vectors for all of its words. Since we're only interested in one word, "the", in this case, the loop could be rewritten like this:
```
# 1.5 seconds for text of 27k words
for i in 1:ntrials
    temp = sample(c[w], N(c); replace = false)
    permuted_p[:, i] .= [p(temp[1:N]) for N in break_pts]
end
```

Even this is only marginally faster than a naive approach of simply shuffling the origin `Vector{String} text` and doing `[sum(text[1:N] .== w) / N for N in break_pts]` on it. The main advantage of this package comes when you have a larger set of words that are of interest, or if you want do something with occurrence counts from the whole vocabulary. 

For example, the function call `V(1, c)` supplied by this package is more than 100x faster than doing the equivalent operation on a `Vector{String} text`:
```
V(1, c)                           #  750 ns (on first execution; faster after that)
sum(values(countmap(text)) .== 1) # 8174 ns
```

Not only that, but calling `V(1, c)` (or similar) caches the results for the whole frequency spectrum so that later calls reduce to 32 ns.


![demo1](https://github.com/myersm0/WordFrequencyDistributions.jl/blob/main/examples/demo1.png)

[![Build Status](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml?query=branch%3Amain)

