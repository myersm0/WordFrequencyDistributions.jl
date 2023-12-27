
"Get the vocabulary elements of the corpus."
ω(c::Corpus) = c.ω

"Get the size of the vocabulary in the corpus."
V(c::Corpus) = c.V

"Get the number of words in the corpus."
N(c::Corpus) = c.N

"Get the frequency of the `i`th word in the corpus."
f(i::Int, c::Corpus) = f(Fast(), i, c)

"Get the frequency of word `w` from the corpus."
f(w::String, c::Corpus) = f(Fast(), w, c)

# "fast" variants of f(...) by default
f(::Fast, i::Int, c::Corpus) = c.f[c.ω[i]]
f(::Fast, w::String, c::Corpus) = c.f[w]

# "safe" variants of f(...) check whether the requested item is in the lexicon or not
f(::Safe, i::Int, c::Corpus) = i <= V(c) ? f(Fast(), i, c) : 0
f(::Safe, w::String, c::Corpus) = occursin(w, c) ? f(Fast(), w, c) : 0

"Get the relative frequency of the `i`th word in the corpus."
p(i::Int, c::Corpus) = p(Fast(), i, c)

"Get the relative frequency of the word `w` from the corpus."
p(w::String, c::Corpus) = p(Fast(), w, c)

# "fast" variants of p(...) by default
p(::Fast, i::Int, c::Corpus) = f(i, c) / N(c)
p(::Fast, w::String, c::Corpus) = f(w, c) / N(c)

# "safe" variants of p(...) check whether the requested item is in the lexicon or not
p(::Safe, i::Int, c::Corpus) = f(Safe(), i, c) / N(c)
p(::Safe, w::String, c::Corpus) = f(Safe(), w, c) / N(c)

"Get the empirical structural type distribution for the `i`th spectrum element in the corpus."
g(m::Int, c::Corpus) = m > c.M ? 0 : sum(c.spectrum[m:end])

"Get the number of words occurring `m` times in the corpus."
V(m::Int, c::Corpus) = c.spectrum[m]

"Get the frequency of the token with the `z`th Zipf rank"
f(z::ZipfRank, c::Corpus) = z > V(c) ? 0 : c.M - findfirst(cumsum(reverse(c.spectrum)) .>= z) + 1

