
"Get the vocabulary elements of the corpus."
ω(c::Corpus) = c.ω[f(c) .> 0]

"Get the number of words in the corpus."
N(c::Corpus) = c.N

"Get the frequency of the `i`th word in the corpus."
f(i::Integer, c::Corpus) = get(f(c), i, 0)

"Get the frequency of word `w` from the corpus."
f(w::String, c::Corpus) = get(f(c), get(c.ωmap, w, 0), 0)

"Get the relative frequency of the `i`th word in the corpus."
p(i::Integer, c::Corpus) = f(i, c) / N(c)

"Get the relative frequency of the word `w` from the corpus."
p(w::String, c::Corpus) = f(w, c) / N(c)

# BitVector alternatives for f and p, e.g. when working with a single occurrence vector
f(x::AbstractVector{Bool}) = sum(x)
p(x::AbstractVector{Bool}) = f(x) / length(x)

"Get the empirical structural type distribution for the `i`th spectrum element in the corpus."
function g(m::Integer, c::Corpus)
	if m > M(c) ÷ 2
		return sum(spectrum(c)[m:M(c)])
	else
		return V(c) - sum(spectrum(c)[1:(m - 1)])
	end
end

"Get the number of words occurring `m` times in the corpus."
V(m::Integer, c::Corpus) = spectrum(c)[m]

"Get the frequency of the token with the `z`th Zipf rank"
f(z::ZipfRank, c::Corpus) = z > V(c) ? 0 : M(c) - findfirst(cumsum(reverse(spectrum(c))) .>= z) + 1

