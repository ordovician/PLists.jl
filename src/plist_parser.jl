export readplist_string, readplist

function parse_obj(p::Parser)
    token = next_token(p)

    if     NUMBER == token.kind
        Meta.parse(token.lexeme)
    elseif STRING == token.kind || IDENT == token.kind
        token.lexeme
    elseif HEXBINARY == token.kind
        parse_hexbinary(token.lexeme)
    elseif LPAREN == token.kind
        backup_token(p)
        parse_array(p)
    elseif LBRACE == token.kind
        backup_token(p)
        parse_dict(p)
    end
end

parse_hexbinary(s::AbstractString) = hex2bytes(filter(isxdigit, s))

function parse_array(p::Parser)
    array = []

    expect(p, LPAREN)
    token = peek_token(p)
    if token.kind == RPAREN
        return array
    end
    push!(array, parse_obj(p))
    token = peek_token(p)
    while token.kind != RPAREN
        expect(p, COMMA)
        push!(array, parse_obj(p))
        token = peek_token(p)
    end
    expect(p, RPAREN)
    array
end

function parse_dict(p::Parser)
    dict =  Dict{Any, Any}()

    expect(p, LBRACE)
    token = peek_token(p)
    while token.kind != RBRACE
        key = parse_obj(p)::String
        expect(p, EQUAL)
        dict[key] = parse_obj(p)
        expect(p, SEMICOLON)
        token = peek_token(p)
    end
    expect(p, RBRACE)
    dict
end

function readplist_string(text::AbstractString)
    l = lex_plist(text)
    p = Parser(l)
    parse_obj(p)
end

function readplist(stream::IO)
    text = read(stream, String)
    readplist_string(text)
end

function readplist(filename::AbstractString)
    open(readplist, filename)
end
