using WordFrequencyDistributions
using Test

# define a vocab of the lowercase ASCII a-z
alphabet = Char.(97:122) .|> string

vowels = ["a", "e", "i", "o", "u"]
consonants = setdiff(alphabet, vowels)
text = repeat(consonants, 100)

vowels_copy = deepcopy(vowels) # because we'll destroy it over this loop
for i in eachindex(text)
	i % 420 == 0 && insert!(text, i, popfirst!(vowels_copy))
end

c = Corpus(text)

@testset "Corpus" begin
	@test all(occursin(letter, c) for letter in alphabet)

	@test all(f(i, c) == 100 for i in 1:length(consonants))
	@test all(f(w, c) == 100 for w in consonants)

	@test all(f(i, c) == 1 for i in (length(consonants) + 1):length(alphabet))
	@test all(f(w, c) == 1 for w in vowels)

	@test V(c) == length(alphabet)
	@test V(1, c) == length(vowels)
	@test V(100, c) == length(consonants)

	c′ = c[101:200]
	@test c′ == Corpus(text[101:200])

	c′ = sample(c, length(consonants); replace = false)
	@test N(c′) == length(consonants)
	@test V(c′) <= length(consonants)

	c′ = sample(c, N(c) * 10; replace = true)
	@test N(c′) == N(c) * 10
	@test V(c′) <= length(alphabet)

	@test all(100p(vowel, c) ≈ p(consonant, c) for vowel in vowels, consonant in consonants)

	@test all(p(Safe(), w, c) == p(Fast(), w, c) for w in alphabet)

	@test g(1, c) == length(alphabet)
	@test all(g(m, c) == length(consonants) for m in 2:100)
end







