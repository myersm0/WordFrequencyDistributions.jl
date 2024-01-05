
using WordFrequencyDistributions
using GLMakie

c = Corpus{Int}(text)

w = "the"
k = 20 # number of steps
ntrials = 1000 # number of Monte Carlo iterations

endpoints = intervals(c; k = k) # 20 equispaced intervals by default

observed_p = [p(w, c[1:t]) for t in endpoints]

permuted_p = zeros(k, ntrials)
for i in 1:ntrials
	c′ = permute(c)
	permuted_p[:, i] .= [p(c′[w][1:t]) for t in endpoints]
end

# notice the slightly different syntax in the right-hand side of the expression 
# in line 18 compared to line 13; they return equivalent results but line 18
# is a little faster in the event that we're just interested in a single word 
# (as is the case here), because at each iteration it just pulls out the occurrence
# vector for just that word, rather than initializing occurrence counts for all words

conf_intervals = map(x -> quantile(x, (0.025, 0.975)), eachrow(permuted_p))

fig = Figure()
ax = Axis(fig[1, 1])
scatter!(ax, endpoints, observed_p; color = :black)
lines!(ax, endpoints, first.(conf_intervals); color = :black, linestyle = :dot)
lines!(ax, endpoints, last.(conf_intervals); color = :black, linestyle = :dot)



