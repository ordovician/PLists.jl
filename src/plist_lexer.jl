export  lex_plist,
        NUMBER, STRING, IDENT,                                                 
        UNKNOWN, ERROR, EOF,
        BEGIN_TAG, END_TAG, CLOSE_TAG, END_AND_CLOSE_TAG,
        HEXBINARY, LPAREN, RPAREN, LBRACE, RBRACE, COMMA, EQUAL, SEMICOLON                                          

@enum(TokenType,
      NUMBER, STRING, IDENT,                                            # Generic
      UNKNOWN, ERROR, EOF,                                              # Control

      # XML
      BEGIN_TAG,         # <tag
      END_TAG,           # >
      CLOSE_TAG,         # </tag>
      END_AND_CLOSE_TAG, # />
      TEXT,              # Text such as "bar" inside tags: <foo>bar</foo>

      # PList
      HEXBINARY,
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
