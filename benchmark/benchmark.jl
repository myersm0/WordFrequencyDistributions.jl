
using WordFrequencyDistributions
using StatsBase
using Pkg.Artifacts
using BenchmarkTools

println("WordFrequencyDistributions.jl - benchmark of a complete workflow")

rootpath = artifact"pg_texts"
filename = joinpath(rootpath, "pg100.txt") # complete Shakespeare

## step 1: read in and tokenize (we'll not include this part in the timing)
println("\n[1/6] Reading and tokenizing the text ...")
text_raw = readlines(joinpath(rootpath, "pg100.txt"))
text = String[]
for line in text_raw
	words = split(lowercase(line), r"[^a-z0-9']+")
	append!(text, filter(w -> length(w) > 0, words))
end

## step 2: create corpus
println("\n[2/6] Creating corpus structure...")
total_start = time()
step_start = time()

c = Corpus(text)

step_time = time() - step_start
println("    ✓ Created corpus with $(V(c)) types in $(round(step_time * 1000, digits=2)) ms")


## step 3: basic statistics
println("\n[3/6] Computing basic statistics ...")
step_start = time()

n_tokens = N(c)
n_types = V(c)
hapaxes = V(1, c)  # words occurring once
dis_legomena = V(2, c)  # words occurring twice

# get top 10 most frequent words
freqs = f(c)
top_indices = sortperm(freqs, rev=true)[1:10]
top_words = [ω(c)[i] for i in top_indices if freqs[i] > 0][1:10]
top_freqs = [freqs[i] for i in top_indices if freqs[i] > 0][1:10]

# vocabulary growth at 20 points
endpoints = intervals(c; k=20)
growth_curve = [V(c[1:t]) for t in endpoints]

step_time = time() - step_start
println("    ✓ Statistics computed in $(round(step_time * 1000, digits=2)) ms")
println("        - Tokens: $n_tokens")
println("        - Types: $n_types")
println("        - Hapax legomena: $hapaxes")
println("        - Top word: '$(top_words[1])' ($(top_freqs[1]) occurrences)")


## step 4: expected vocabulary size
println("\n[4/6] Computing expected vocabulary sizes ...")
step_start = time()

# binomial interpolation at multiple points
sample_points = [1000, 5000, 10000, 15000, 20000]
expected_v = Float64[]
for t in sample_points
	if t < N(c)
		push!(expected_v, V(BinomialExpectation(), c; t=t))
	end
end

step_time = time() - step_start
println("    ✓ Computed $(length(expected_v)) interpolations in $(round(step_time * 1000, digits=2)) ms")


## step 5: dispersion analysis
println("\n[5/6] Analyzing word dispersion...")
step_start = time()

# calculate dispersion for a specific word
target_word = "wounds"
if occursin(target_word, c)
	# get dispersion across 40 partitions
	k = 40
	partition_size = N(c) ÷ k
	dispersions = Int[]
	for i in 1:k
		start_idx = (i-1) * partition_size + 1
		end_idx = min(i * partition_size, N(c))
		subcorpus = c[start_idx:end_idx]
		push!(dispersions, occursin(target_word, subcorpus) ? 1 : 0)
	end
	dispersion_rate = sum(dispersions) / k
	step_time = time() - step_start
	println("      ✓ '$target_word' appears in $(round(dispersion_rate * 100, digits=1))% of partitions")
	println("        Computed in $(round(step_time * 1000, digits=2)) ms")
else
	step_time = time() - step_start
	println("      ✓ Word '$target_word' not found ($(round(step_time * 1000, digits=2)) ms)")
end


## step 6: Monte Carlo simulation
println("\n[6/6] Running Monte Carlo simulation ...")
println("    Testing hypothesis: the word 'the' is not randomly distributed")
step_start = time()

word = "the"
n_permutations = 100
n_checkpoints = 20

endpoints = intervals(c; k=n_checkpoints)
observed_freqs = [p(word, c[1:t]) for t in endpoints]

permuted_freqs = zeros(n_checkpoints, n_permutations)
for i in 1:n_permutations
	c_perm = permute(c)
	for (j, t) in enumerate(endpoints)
		permuted_freqs[j, i] = p(word, c_perm[1:t])
	end
	if i % 20 == 0
		print("      $(i)/$(n_permutations) permutations...")
		println(" $(round((time() - step_start) * 1000, digits=1)) ms elapsed")
	end
end

# calculate confidence intervals
ci_lower = [quantile(permuted_freqs[i, :], 0.025) for i in 1:n_checkpoints]
ci_upper = [quantile(permuted_freqs[i, :], 0.975) for i in 1:n_checkpoints]

# count how many observed points fall outside CI
outside_ci = sum((observed_freqs .< ci_lower) .| (observed_freqs .> ci_upper))

step_time = time() - step_start
println("    ✓ Completed $(n_permutations) permutations in $(round(step_time * 1000, digits=2)) ms")
println("        $(outside_ci)/$(n_checkpoints) points outside 95% CI")
if outside_ci > n_checkpoints / 2
	println("        → 'the' is NOT randomly distributed (p < 0.05)")
else
	println("        → Cannot reject random distribution")
end

total_time = time() - total_start
println("Total workflow time: $(round(total_time, digits=3)) seconds")

