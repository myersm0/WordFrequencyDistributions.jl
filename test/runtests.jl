using WordFrequencyDistributions
using Test

# define a vocab of the lowercase ASCII a-z
alphabet = Char.(97:122) .|> string

vowels = ["a", "e", "i", "o", "u"]
consonants = setdiff(alphabet, vowels)
text = repeat(vowels, 21)

for i in eachindex(text)
	i % 5 == 0 && insert!(text, i + i ÷ 5, consonants[i ÷ 5])
end

c = Corpus(text)

subsets = [
	1:6, 
	collect(7:(6 * 4)), 
	union(1:length(vowels), reverse(Int.(range(101, 126; step = 5))))
]

@testset "Corpus" begin
	@test all(occursin(letter, c) for letter in alphabet)

	@test all(f(i, c) == 21 for i in 1:length(vowels))
	@test all(f(w, c) == 21 for w in vowels)

	@test all(f(i, c) == 1 for i in (length(vowels) + 1):length(alphabet))
	@test all(f(w, c) == 1 for w in consonants)

	@test V(c) == length(alphabet)
	@test V(1, c) == length(consonants)
	@test V(21, c) == length(vowels)

	@test all(occurrences(letter, c) == (text .== letter) for letter in alphabet)

	for inds in subsets
		c′ = c[inds]
		@test c′ == Corpus(text[inds])
		@test N(c′) == length(inds)
		@test sum(m * V(m, c) for m in c.m) == N(c)
	end

	c′ = sample(c, length(consonants); replace = false)
	@test N(c′) == length(consonants)
	@test V(c′) <= length(consonants)

	c′ = sample(c, N(c) * 10; replace = true)
	@test N(c′) == N(c) * 10
	@test V(c′) <= length(alphabet)

	@test all(21p(consonant, c) ≈ p(vowel, c) for consonant in consonants, vowel in vowels)

	@test all(p(Safe(), w, c) == p(Fast(), w, c) for w in alphabet)

	@test g(1, c) == length(alphabet)
	@test all(g(m, c) == length(vowels) for m in 2:c.M)
end




