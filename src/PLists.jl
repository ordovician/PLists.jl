module PLists

isalnum(c::Char) = isletter(c) || isnumeric(c)

include("plist_lexer.jl")
include("xml_lexer.jl")
include("parser.jl")
include("plist_parser.jl")
include("plist_writer.jl")
include("xml_dom.jl")
include("xml_parser.jl")
include("xml_show.jl")
include("xml_plist_parser.jl")

end
