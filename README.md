# WordFrequencyDistributions
A Julia implementation of some of the techniques for estimating and analyzing word frequency statistics, from R. Harald Baayen's book _Word Frequency Distributions_ (Springer, 1996).

Operations center around the `Corpus` struct, which was designed to provide balanced performance over a range of operations that the book discusses:
- Initializing a `Corpus` from a `Vector{String}`, including calculation of the frequency counts for each word in its vocabulary
- Subsetting or sampling a `Corpus` to capture its frequency characteristics only within a certain range or over a random set of indices

A `Corpus` may be a single text (the text of a novel, for example) or a collection of documents. However, in either case, the words are simply stored as a single homogenous entity, and the document divisions (if any) are not recoverable or of interest.

Function and field names were chosen as a compromise between fidelity to Baayen's notation in the book, and the goal of having a sensible, consistent interface to all the functions. The main exception is where the book names something like `V(N)` (the size of the vocabulary in a corpus of N words), in this package I implement that as `V(c::Corpus)`, where the corpus `c` encapsulates `N`. To evaluate `V()` on a smaller sample, such as on the first 1000 words of `c`, you would subset your corpus like this:
```
smaller_corpus = c[1:1000]
V(smaller_corpus)
```

## Usage
If I have a vector of strings called `text` (e.g. tokenized from a document), constructing a `Corpus` struct is simple:
```
c = Corpus(text)
```

To generate another corpus (at little cost) that's just the first 1000 tokens of `text`:
```
c[1:1000]

# or, equivalently:
Corpus(text[1:1000])
```

Below I demonstrate creation of a figure similar to one that Baayen shows in Chapter 1. Here we are using the observed relative sample frequency `p` of the word "the" in the text, in 20 intervals of increasing size along with Monte Carlo confidence intervals generated from 1000 random permutations of the text:
```
w = "the"

break_pts = intervals(c)
observed_p = map(N -> p(c[w][1:N]), break_pts)

ntrials = 1000
nsteps = 20
permuted_p = zeros(nsteps, ntrials)
Threads.@threads for i in 1:ntrials
	c′ = permute(c)
	permuted_p[:, i] .= map(N -> p(c′[w][1:N]), break_pts)
end

conf_intervals = map(x -> quantile(x, (0.05, 0.95)), eachrow(permuted_p))

using GLMakie

fig = Figure()
ax = Axis(fig[1, 1])
scatter!(ax, break_pts, observed_p; color = :black)
lines!(ax, break_pts, [first(x) for x in conf_intervals]; color = :black, linestyle = :dot)
lines!(ax, break_pts, [last(x) for x in conf_intervals]; color = :black, linestyle = :dot)
```

![demo1](https://github.com/myersm0/WordFrequencyDistributions.jl/blob/main/examples/demo1.png)

[![Build Status](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml?query=branch%3Amain)

