
using WordFrequencyDistributions
using GLMakie
using Optim

# this will tokenize the text of Alice in Wonderland; by the way, there are probably
# better ways to do it, but I've done it this way to try to figure out and replicate
# the method Baayen used in his book. I wasn't completely successful in that though,
# but close
include(joinpath(dirname(@__FILE__), "tokenize.jl"))

# from the above, we now have a Vector{String} called text in our environment

c = Corpus{Int}(text)

# in this example we'll approximately reproduce figure 1.9 from Baayen, plotting 
# the fit of Zipfian estimates to the frequency spectrum in Alice in Wonderland

# first, find optimal params of C, μ, and γ to pass into Naranan-Balasubrahmanyan's
# Zipfian smoother. To do this we'll define a function 𝑓 to be optimized and then 
# use a Nelder-Mead optimizer from the Optim.jl package:

𝑓(params) = loss(
	MSE(), c;
	y = (m, c) -> V(m, c),
	yhat = (m, c) -> V(NaranBalasub(), m, c; C = params[1], μ = params[2], γ = params[3]),
	spectra = 1:40
)

# note: you should probably compare results from  multiple initialization points, 
# not just [0, 0, 0] as here
result = optimize(𝑓, [0.0, 0.0, 0.0], NelderMead())
params = Dict(k => v for (k, v) in zip([:C, :μ, :γ], result.minimizer))

# now compute and plot the observed and fitted values
ys = [V(GaleSampson(), m, c) for m in 1:M(c)]
yhats_zipf = [V(Zipf(), m, c) for m in 1:M(c)]
yhats_nb = [V(NaranBalasub(), m, c; params...) for m in 1:M(c)]

fig = Figure(; size = (750, 900))
ax1 = Axis(fig[1, 1])
ax2 = Axis(fig[1, 2])
ylims!(ax1, (-7.25, 7.25))
ylims!(ax2, (-7.25, 7.25))

scatter!(ax1, log.(1:M(c)), log.(ys); color = :black, marker = 'o')
lines!(ax1, log.(1:M(c)), log.(yhats); color = :black)

scatter!(ax2, log.(1:M(c)), log.(ys); color = :black, marker = 'o')
lines!(ax2, log.(1:M(c)), log.(yhats); color = :black)

