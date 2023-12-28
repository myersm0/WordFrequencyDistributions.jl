
@kwdef struct Corpus
	source::Vector{String}
	ω::Vector{String}
	ωmap = Dict(w => i for (i, w) in enumerate(ω))
	occurrences::Lazy.LazyList
	V::Int = length(ω)
	N::Int = V == 0 ? 0 : length(source)
	f::Ref{Union{Nothing, Vector{Int}}} = nothing
	spectrum::Ref{Union{Nothing, Vector{Int}}} = nothing
	m::Ref{Union{Nothing, Vector{Int}}} = nothing
	M::Ref{Union{Nothing, Int}} = nothing
end

function f(c::Corpus)
	isnothing(c.f[]) && (c.f[] = [sum(x) for x in c.occurrences])
	return c.f[]
end

function spectrum(c::Corpus)
	isnothing(c.spectrum[]) && (c.spectrum[] = counts(f(c)))
	return c.spectrum[]
end

function m(c::Corpus)
	isnothing(c.m[]) && (c.m[] = findall(spectrum(c) .!= 0))
	return c.m[]
end

function M(c::Corpus)
	isnothing(c.M[]) && (c.M[] = m(c)[end])
	return c.M[]
end

function Corpus(v::Vector{String})
	ω = unique(v)
	occurrences = Lazy.@lazy [v .== w for w in ω]
	return Corpus(source = v, ω = ω, occurrences = occurrences)
end

function Base.getindex(
		c::Corpus, rng::Union{AbstractVector{T}, AbstractRange{T}}
	) where T <: Integer
	source = c.source[rng]
	ω = unique(source)
	occurrences = Lazy.@lazy [c.occurrences[i][rng] for i in eachindex(ω)]
	return Corpus(source = source, ω = ω, occurrences = occurrences)
end

function Base.getindex(c::Corpus, w::Union{String, Vector{String}})
	return c.occurrences[c.ωmap[w]]
end

function StatsBase.sample(c::Corpus, args...; kwargs...)
	inds = sample(1:N(c), args...; kwargs...)
	return c[inds]
end

function StatsBase.sample(c::Corpus)
	inds = sample(1:N(c), N(c); replace = false)
	return c[inds]
end

Base.occursin(w::String, c::Corpus) = haskey(c.ωmap, w)

function Base.:(==)(c1::Corpus, c2::Corpus)
	return ω(c1) == ω(c2) && occurrences(c1) == occurrences(c2)
end

occurrences(w::String, c::Corpus) = c[w]

"Get `nsteps` equispaced points from 1 to N(c::Corpus)`."
function intervals(c::Corpus; nsteps = 20)
	step_size = Int(round(N(c) / nsteps))
	rng = range(step_size, step_size * nsteps, nsteps) |> collect .|> Int
	rng[end] = N(c)
	return rng
end

function Base.show(io::IO, mime::MIME"text/plain", c::Corpus)
	println("OK")
end





