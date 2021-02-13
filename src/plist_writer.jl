export writeplist_string, writeplist

"""
     writeplist_string(obj) -> String 
     
Returns a NeXTSTEP PList formatted string of the `obj` object. `obj` could
be a string, number or nested dictionary.
""" 
writeplist_string(obj) = encode(obj)

"""
     writeplist(stream::IO, obj)
     writeplist(filename::AbstractString, obj)
     
Write an object to an IO `stream` or to a file named `filename` using the
NeXTSTEP property list format. The `obj` could be a dictionary, number or string.
"""    
function writeplist(stream::IO, obj)
    print(stream, encode(obj))
end    

function writeplist(filename::AbstractString, obj)
    open(filename, "w") do stream
        writeplist(stream, obj)
    end
end

encode(key::AbstractString, obj) = string(key, " = ", encode(obj), ";")

function encode(dict::Dict{K, V}) where {K, V}
    string("{", join([encode(key, value) for (key, value) in dict]), "}")
end

function encode(array::Vector{T}) where T
    string( "(", join(map(encode, array), ", "), ")")
end

# Quotes strings which are not simple alphanumeric. 
function encode(s::AbstractString)
    if all(isalnum, s) && length(s) > 0 && isletter(s[1])
        s
    else
        "\"$s\""
    end
end

function encode(binary::Vector{UInt8})
    string("<", bytes2hex(binary), ">")
end

encode(num::Real) = string(num)

function encode(obj)
    error("Can't encode $obj because it is of type $(typeof(obj))")
end
