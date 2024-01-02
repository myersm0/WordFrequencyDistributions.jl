# WordFrequencyDistributions
A Julia implementation of some of the techniques for estimating and analyzing word frequency statistics, from R. Harald Baayen's book _Word Frequency Distributions_ (Springer, 2001).

Operations center around the `Corpus` struct, which was designed to provide excellent performance over a range of operations that the book discusses. A `Corpus` is both very fast and memory-efficient; even after initializing auxiliary fields, its RAM usage tends to be about the same as that of the original text vector it was constructed from.

A `Corpus` may be a single text (the text of a novel, for example) or a collection of documents. However, in either case, the words are simply stored as a single homogenous entity, and the document divisions (if any) are not recoverable or of interest.

An example application is given in `examples/lexical_specialization.jl`, where I show how these concepts could be used to evaluate document clusters from an unsupervised topic modeling scheme.

## Notation
Function and field names were chosen as a compromise between fidelity to Baayen's notation in the book, and the goal of having a nice, consistent interface to all the functions. I apologize for having violated style conventions by using capitals for some function names (V, N, etc), but otherwise I would have had to impose a very different naming scheme of my own, and that seemed contrary to my goals here. So, functions in this package are designed to resemble equations from the book as much as possible.

The main exception is where the book names something like `V(N)` (where N is the number of tokens in a corpus); in this package, I implement that as `V(c::Corpus)`, where the corpus `c` encapsulates `N`, among other things.

Another deviation from Baayen's notation is that in cases of interpolation or extrapolation of vocabulary size, Baayen uses N_0 to represent the size of the corpus on which the estimate is conditioned and N for the sample size at which to interpolate or extrapolate. Instead, I let `N` keep its original meaning (the number of tokens in a corpus), and I use `t` (for "text time") to denote the point at the text, measured in tokens, at which to interpolate/extrapolate.

Finally, in cases where Baayen names things such as the "characteristic constants" Yule's _K_, Simpson's _D_, Zipf size _Z_, etc., I've instead named these functions all `C` for characteristic constant and provided trait-based dispatch to distinguish them, such as `C(::Yule, args...)` and `C(::Simpson, args...)`, to emphasize their similar nature and to reduce the alphabet-soup aspect of the interface somewhat.


## Usage
If you have a vector of strings called `text` (e.g. tokenized from a document), constructing a `Corpus` struct is simple:
```
c = Corpus(text)
```

Some basic operations:
```
N(c)        # the number of tokens in `c`
V(c)        # the number of distinct words (types) in `c`
V(999, c)   # the number of types in `c` occurring exactly 999 times
g(999, c)   # the number of types occurring at least 999 times
spectrum(c) # accessor for the whole frequency spectrum V(m, c)
```

To evaluate statistics on a smaller sample, such as on the first 1000 words of `c`, you would subset your corpus like this:
```
smaller_corpus = c[1:1000]
V(smaller_corpus) # get the size of the vocabulary in the reduced corpus
N(smaller_corpus) # the total number of words in the reduced corpus (1000)
```

You can also sample or permute a corpus. The difference is only one of notation; `permute` here is just a complete reordering of the word occurrences. These two operations are the same:
```
sampled_corpus = sample(c, N(c); replace = false)
permuted_corpus = permute(c)
```

You can break your corpus up into a vector of 20 smaller ones via:
```
chunks = partition(c; k = 20)
```

A related operation is getting a certain number of equispaced points in the corpus, e.g. 20:
```
break_pts = intervals(c; k = 20)
```

For sample and population statistics relating to your corpus, the general pattern of functions offered is as follows: `𝑓([::Estimator,] args...; kwargs...)`. If you omit the first argument, an `Estimator`, then the operation is performed empirically on the observed sample. Otherwise, you may supply an `Estimator` for which an estimation method is defined. Here are a few different ways to compute the number of distinct tokens (types) that occur exactly once in a corpus `c`.
```
# actual number of words in the observed sample that occur exactly once:
V(1, c)

# Gale and Sampson's Zipfian smoother to derive a theoretical value of V(1, c):
V(GaleSampson(), 1, c)

# binomial expectation for the value of V(1, c), conditioned on the full corpus `c` 
# and interpolated at "text time" t = 10602 (i.e. ~10k words into the corpus):
V(BinomialExpectation(), 1, c; t = 10602)
```

A couple of loss functions are implemented, which you can use like this:
```
# set up a couple of higher-order functions which we'll compare below:
observed = (m, c) -> V(m, c[1:10602])
expected = (m, c) -> V(BinomialExpectation(), m, c; t = 10602)

# calculate the MSE of using the binomial expectation of V(m, c) relative to
# the actual observed value, over the range of spectrum elements 1 through 15:
loss(MSE(), c; y = observed, yhat = expected, spectra = 1:15)

# as above, but use the relative MSE variant, "MSEr" (equation 3.2 from Baayen):
loss(MSEr(), c; y = observed, yhat = expected, spectra = 1:15)
```

## Performance notes and comparison to ZipfR
There's already an excellent package in the R language for the things implemented here (and more), [zipfR](http://zipfr.r-forge.r-project.org). With the current package, I wanted to see if I could improve on the performance in terms of both speed and capacity for handling large corpora.

I found two things. One, the performance of zipfR is already excellent. Two, it's hard to compare the two packages directly, because they operate very differently and because use cases can differ so much. For example:
- for initialization of a corpus of 27k tokens, I get a 1.97 ms initialization time in this package, compared to 6.16 ms with zipfR. For larger corpora however, zipfR comes out ahead
- this package comes out ahead in subsetting and sampling operations (e.g. for subsetting and computing occurrence statistics for the first 1000 tokens of `c`, I get 31 μs in this package versus 588 μs in zipfR; performance gains in this respect are similar for random sampling and for larger sizes)

The reasons for the performance difference behind both of these examples is the same: this package does more work upfront in constructing the corpus, in order to facilite fast subsetting and sampling later on.

[![Build Status](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/myersm0/WordFrequencyDistributions.jl/actions/workflows/CI.yml?query=branch%3Amain)

