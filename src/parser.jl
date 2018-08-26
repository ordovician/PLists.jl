export  Parser,
        next_token, peek_token, backup_token,
        peek_token_type,
        expect

"Only evaluate and return `default` expression if `nullable` is null"
macro get(nullable, default)
    quote
        if $(esc(nullable)) == nothing
            $(esc(default))
        else
            $(esc(nullable))
        end
    end
end

"Keeps track of current state of parsing."
mutable struct Parser
    lexer::Lexer
    ahead_token::Union{Token, Nothing}
    backup_token::Union{Token, Nothing}
    function Parser(lexer::Lexer)
        null = nothing
        new(lexer, null, null)
    end
end

function show(io::IO, p::Parser)
    print(io, "Parser($(p.lexer)")
    
    if p.ahead_token != nothing
        print(", $(get(p.ahead_token))") 
    end
    
    if p.backup_token != nothing
        print(", $(get(p.backup_token))") 
    end
    print(")")
end

"Move to next token from lexer"
function next_token(p::Parser)
    t = @get(p.ahead_token, next_token(p.lexer))
    p.backup_token = t
    p.ahead_token  = nothing 
    t
end

function peek_token(p::Parser)
    t = @get(p.ahead_token, next_token(p.lexer))
    p.ahead_token = t
    t
end

peek_token_type(p::Parser) = token_type(peek_token(p))

function backup_token(p::Parser)
    p.ahead_token = p.backup_token
end

"""
    expect(parser, token_type)

Verify that next token is of type `token_type`, and if so, get next token.
"""
function expect(p::Parser, kind::TokenType)
    if  token_type(peek_token(p)) == kind
        next_token(p)
    else
        error("Expected $(Token(kind)) but got $(peek_token_type(p))")
    end
end