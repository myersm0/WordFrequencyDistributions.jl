
@kwdef struct Corpus{T1, T2 <: Integer}
	source::Vector{T2}
	ωmap::Dict{T1, T2}
	N::Int = length(source)
	f::Vector{Int} = counts(source, length(ωmap))
	V::Int = sum(f .> 0)
	spectrum::Vector{Int} = counts(f, length(ωmap))
	m⃗::Vector{Int} = findall(spectrum .!= 0)
end

"""
	Corpus{T}(text)

Initialize a `Corpus{T}` from a vector of strings `text`. The token count should
not exceed `typemax(T)`.
"""
function Corpus{T1, T2}(text::Vector{T1}) where {T1, T2 <: Integer}
	N = length(text)
	ωmap = Dict{T1, T2}()
	sizehint!(ωmap, 27000)
	source = Vector{T2}(undef, N)
	next_id = T2(1)
	@inbounds for i in 1:N
		word = text[i]
		id = get!(ωmap, word) do
			current = next_id
			next_id += 1
			current
		end
		source[i] = id
	end
	V = length(ωmap)
	V <= typemax(T2) || error("Number of unique words exceeds typemax for Corpus{$(T2)}")
	return Corpus{T1, T2}(source = source, ωmap = ωmap, N = N, V = V)
end

"""
	Corpus(text)

Initialize a `Corpus{UInt16}` from a vector of strings `text`.
"""
Corpus(text::Vector{String}) = Corpus{String, UInt16}(text)

Corpus(text::Vector{T1}) where T1 = Corpus{T1, UInt16}(text)

"""
	getindex(c, rng)

Turn `Corpus c` into a smaller corpus using only its tokens in `rng`.
"""
function Base.getindex(
		c::Corpus{T1, T2}, rng::Union{AbstractVector{<: Integer}, AbstractRange{<: Integer}}
	) where {T1, T2}
	return Corpus{T1, T2}(source = c.source[rng], ωmap = c.ωmap)
end

"""
	getindex(c, w)

Get a binary occurrence vector of the word `w` in `Corpus c`.
"""
function Base.getindex(c::Corpus{T1, T2}, w::T1) where {T1, T2}
	return c.source .== c.ωmap[w]
end

"""
	sample(c, args...; kwargs...)

Make a new `Corpus` by randomly sampling the tokens from `c`.
"""
function StatsBase.sample(c::Corpus, args...; kwargs...)
	return c[sample(1:N(c), args...; kwargs...)]
end

"""
	sample(c, args...; kwargs...)

Make a new `Corpus` by shuffling all the tokens from `c`.
"""
function permute(c::Corpus)
	return sample(c, N(c); replace = false)
end

"""
	occursin(w, c)

Check if word `w::String` occurs in `c::Corpus`.
"""
function Base.occursin(w::T1, c::Corpus{T1, T2}) where {T1, T2}
	return haskey(c.ωmap, w) && f(c)[c.ωmap[w]] != 0
end

"""
	intervals(c; k)

Get `k` (default: 20) equispaced points from 1 to N(c)`.
"""
function intervals(c::Corpus; k::Int = 20)
	step_size = N(c) ÷ k
	step_size > 0 || error(DomainError)
	rem = N(c) % k
	rng = range(step_size, step_size * k, k) |> collect .|> Int
	rng[k:-1:(k - rem + 1)] .+= rem:-1:1
	return rng
end

"""
	 partition(c; k, endpoints)

Partition `c::Corpus` into a `Vector{Corpus}` of length `k` (by default, 40). Or supply 
a vector of predefined `endpoints` for the partitions, in which case `k` is ignored.
"""
function partition(
		c::Corpus; k::Int = 20, endpoints::Vector{<: Integer} = intervals(c; k = k)
	)
	return [c[1 + (i == 1 ? 0 : endpoints[i - 1]):endpoints[i]] for i in eachindex(endpoints)]
end

function Base.show(io::IO, mime::MIME"text/plain", c::Corpus)
	print(io, "Corpus with $(N(c)) tokens, $(V(c)) types")
end

function Base.:(==)(c1::Corpus, c2::Corpus)
	f1 = f(c1)
	f2 = f(c2)
	return all(x in ω(c2) for x in ω(c2)) && f1[f1 .!= 0] == f2[f2 .!= 0]
end


# ===== lazy field initializers ================================================

function V(c::Corpus)
	return c.V
end

function f(c::Corpus)
	return c.f
end

function spectrum(c::Corpus)
	return c.spectrum
end

function m⃗(c::Corpus)
	return c.m⃗
end

function M(c::Corpus)
	return m⃗(c)[end]
end


