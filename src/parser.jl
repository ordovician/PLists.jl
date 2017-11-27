export  Parser,
        next_token, peek_token, backup_token,
        peek_token_type,
        expect

"Only evaluate and return `default` expression if `nullable` is null"
macro get(nullable, default)
    quote
        if isnull($(esc(nullable)))
            $(esc(default))
        else
            get($(esc(nullable)))
        end
    end
end

"Keeps track of current state of parsing."
mutable struct Parser
    lexer::Lexer
    ahead_token::Nullable{Token}
    backup_token::Nullable{Token}
    function Parser(lexer::Lexer)
        null = Nullable{Token}()
        new(lexer, null, null)
    end
end

function show(io::IO, p::Parser)
    print(io, "Parser($(p.lexer)")
    
    if !isnull(p.ahead_token)
        print(", $(get(p.ahead_token))") 
    end
    
    if !isnull(p.backup_token)
        print(", $(get(p.backup_token))") 
    end
    print(")")
end

"Move to next token from lexer"
function next_token(p::Parser)
    t = @get(p.ahead_token, next_token(p.lexer))
    p.backup_token = Nullable(t)
    p.ahead_token  = Nullable{Token}() 
    t
end

function peek_token(p::Parser)
    t = @get(p.ahead_token, next_token(p.lexer))
    p.ahead_token = Nullable(t)
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