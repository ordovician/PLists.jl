"""
    chr2ind(s, i, offset)
    
Find a byte index for character in string `s`. 
We start at **byte index** `i` with an `offset` number of characters.
"""
function chr2ind(s::AbstractString, i::Integer, offset::Integer)
    k = i
    if offset < 0
        for j in 1:abs(offset)
            k = prevind(s, k)
        end        
    elseif offset > 0
        for j in 1:offset
            k = nextind(s, k)
        end
    end
    clamp(k, 1, lastindex(s))
end