
struct ZipfRank
	rank::Int
	function ZipfRank(rank::Int)
		rank > 0 || error(DomainError)
		return new(rank)
	end
end

Base.:(<)(z::ZipfRank, args...) = <(z.rank, args...)
Base.:(>)(z::ZipfRank, args...) = >(z.rank, args...)
Base.:(==)(z::ZipfRank, args...) = ==(z.rank, args...)

Broadcast.broadcastable(z::ZipfRank) = z.rank

