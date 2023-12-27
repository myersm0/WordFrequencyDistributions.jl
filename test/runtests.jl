using WordFrequencyDistributions
using Test
using Chain

# define a vocab of the lowercase ASCII a-z
ω = Char.(97:122) .|> string

vowels = ["a", "e", "i", "o", "u"]
consonants = setdiff(ω, vowels)
text = repeat(consonants, 100)

vowels_copy = deepcopy(vowels) # because we'll destroy it over this loop
for i in eachindex(text)
	i % 420 == 0 && insert!(text, i, popfirst!(vowels_copy))
end

c = Corpus(text)

@testset "Corpus" begin




