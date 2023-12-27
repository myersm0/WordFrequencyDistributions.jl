# WordFrequencyDistributions
A Julia implementation of some of the techniques for estimating and analyzing word frequency statistics in linguistic texts, from R. Harald Baayen's book _Word Frequency Distributions_ (Springer, 1996).

Operations center around the `Corpus` struct, which was designed to provide balanced performance over a range of operations that the book discusses:
- Initializing a `Corpus` from a `Vector{String}`, including calculation of the frequency counts for each word in its vocabulary
- Subsetting or sampling a `Corpus` to capture its frequency characteristics only within a certain range or over a random set of indices

A `Corpus` may be a single text (the text of a novel, for example) or a collection of documents; however, in the latter case, the words are simply stored as a single homogenous entity, and the document divisions are not recoverable or of interest.

Names were chosen as a compromise between fidelity to Baayen's notation in the book, and my goal of having a sensible, consistent interface to all the functions. The main exception is where the book names something like `V(N)` (the size of the vocabulary in a corpus of N words), in this package I implement that as `V(c::Corpus)`, where the corpus `c` already provides the `N`. To evaluate `V()` on a smaller sample, such as on the first 1000 words of `c`, you would subset your corpus like this:
```
smaller_corpus = c[1:1000]
V(smaller_corpus)
```

[![Build Status](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml?query=branch%3Amain)
