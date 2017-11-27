export  lex_plist,
        NUMBER, STRING, IDENT,                                                 
        UNKNOWN, ERROR, EOF,
        HEXBINARY, LPAREN, RPAREN, LBRACE, RBRACE, COMMA, EQUAL, SEMICOLON                                          

@enum(TokenType,
      NUMBER, STRING, IDENT,                                            # Generic
      UNKNOWN, ERROR, EOF,                                              # Control
      HEXBINARY,                                                        # PList
      LPAREN = Int('('),                                                 
      RPAREN = Int(')'),
      LBRACE = Int('{'),
      RBRACE = Int('}'),
      COMMA  = Int(','),
      EQUAL  = Int('='),
      SEMICOLON = Int(';'))

include("token.jl")
include("lexer.jl")
include("basiclexer.jl")

function lex_plist(input::String)
    lex(input, lex_basic)
end
