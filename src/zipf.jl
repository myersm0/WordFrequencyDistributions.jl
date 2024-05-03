
struct ZipfRank
	rank::Int
	function ZipfRank(rank::Int)
		rank > 0 || error(DomainError)
		return new(rank)
	end
end

Base.isless(z::ZipfRank, args...) = isless(z.rank, args...)
Base.isless(a::ZipfRank, b::ZipfRank) = isless(a.rank, b.rank)

