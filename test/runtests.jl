using WordFrequencyDistributions
using Test
using Chain
using StatsBase
using Pkg.Artifacts

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

	@test all(f(c[letter]) == (letter in vowels ? 21 : 1) for letter in alphabet)

	@test V(c) == length(alphabet)
	@test V(1, c) == length(consonants)
	@test V(21, c) == length(vowels)

	@test all(occurrences(letter, c) == (text .== letter) for letter in alphabet)

	for inds in subsets
		c′ = c[inds]
		@test c′ == Corpus(text[inds])
		@test N(c′) == length(inds)
		@test sum(m * V(m, c′) for m in m⃗(c′)) == N(c′)
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
	@test all(g(m, c) == length(vowels) for m in 2:M(c))

	partitions = partition(c; k = 21)
	for c′ in partitions
		@test V(c′) == N(c′) == 6
	end

	partitions = partition(c)
	@test sum(N.(partitions)) == N(c)
	@test maximum(diff(N.(partitions))) <= 1
end


## Set up "Alice in Wonderland" text to match results from Baayen 2001

rootpath = artifact"pg_texts"
filename = joinpath(rootpath, "pg11.txt") # Alice in Wonderland

# attempt to tokenize in the exact way Baayen did in the book
lines = readlines(filename)[54:3403]
chapter_starts = findall(occursin.(r"^CHAPTER", lines))
chapter_names = chapter_starts .+ 1
lines = lines[setdiff(1:length(lines), chapter_starts)]

tokenize(str::String) = @chain split(str, r"[^a-z0-9'’-]+") filter(x -> x !=     "", _)

# this comes very close to Baayen's N = 26505, V = 2651:
text = @chain lines begin
	filter(x -> x != "", _)
	[x |> lowercase |> tokenize for x in _]
	vcat(_...)
	string.(_)
	filter(x -> occursin(r"[a-z0-9]", x), _)
end

c = Corpus(text)
endpoints = intervals(c)

# aim to do this better later; for now, since I can't exactly replicate the
# tokenization from the book, these results match Baayen's closely enough
@testset "CharacteristicConstants" begin
	yule = [C(Yule(), c[1:n]) for n in endpoints]
	simpson = [C(Simpson(), c[1:n]) for n in endpoints]
	@test cor(simpson, yule) > 0.9999
	@test yule[1] ≈ 102.4640045135
	@test yule[end] ≈ 102.2274628004

	guiraud = [C(Guiraud(), c[1:n]) for n in endpoints]

	brunet = [C(Brunet(), c[1:n]) for n in endpoints]
	@test brunet[1] ≈ 12.85455913
	@test brunet[end] ≈ 14.37354565

	sichel = [C(Sichel(), c[1:n]) for n in endpoints]
	@test sichel[1] ≈ 0.1700680272
	@test sichel[end] ≈ 0.1560150375

	honore = [C(Honore(), c[1:n]) for n in endpoints]
	@test honore[1] ≈ 1742.173449
	@test honore[end] ≈ 1828.201155
end



