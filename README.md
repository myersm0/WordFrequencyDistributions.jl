# WordFrequencyDistributions
A Julia implementation (in progress) of the word frequency measures from R. Harald Baayen's book _Word Frequency Distributions_ (Springer, 1996).

Operations center around the `Corpus` struct, which was designed to provide balanced performance over a range of operations that the book discusses:
- Initializing a `Corpus` from a `Vector{String}`, including calculation of the frequency counts for each word in its vocabulary
- Subsetting or sampling a `Corpus` to capture its frequency characteristics only within a certain range or over a random set of indices

[![Build Status](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml?query=branch%3Amain)
