import Base: error, convert, show

export  Lexer, Token,
        lex, lex_end, scan_number, scan_string,
        ignore, ignore_whitespace,
        next_char, backup_char, peek_char, current_char,
        accept_char, accept_char_run,
        emit_token, lexeme,
        next_token, drain

include("util.jl")

const EOFChar = Char(0xC0) # Using illegal UTF8 as sentinel

# Because it is practical to use single chars as tokens sometimes
TokenType(ch::Char) = TokenType(Int(ch))
Char(t::TokenType)  = Char(Int(t))


"Keeps track of string of code we want to turn into array of tokens"
mutable struct Lexer
	input	:: String # string being scanned
	start	:: Int    # start position of this item (lexeme)
	pos		:: Int    # current position in the input
    tokens  :: Channel{Token}
	function Lexer(input::String)
		l = new(input, 1, 0, Channel{Token}(32))
		return l
	end
end

function show(io::IO, l::Lexer)
    print(io, "Lexer($(l.start), $(l.pos))")
end

"Advance the lexers position in the input"
function next_char(l::Lexer)
	l.pos = nextind(l.input, l.pos)
    if l.pos > lastindex(l.input)
		return EOFChar
	end
	return l.input[l.pos]
end

"Go one character back in input string"
function backup_char(l::Lexer)
	l.pos = prevind(l.input, l.pos)
	return l.input[l.pos]
end

"Check what the next character will be"
function peek_char(l::Lexer)
	pos = nextind(l.input, l.pos)
    if pos > lastindex(l.input)
		return EOFChar
	end
	return l.input[pos]
end

function current_char(l::Lexer)
	if l.pos < 1
		error("Can't ask for current char before first char has been fetched")
    elseif l.pos > lastindex(l.input)
        return EOFChar
	end
	return l.input[l.pos]
end

"Check if next character is one of among the valid ones"
function accept_char(l::Lexer, valid::AbstractString)
    if peek_char(l) in valid
		next_char(l)
        return true
	end
	return false
end

"Accept a run of characters contained withing array of valid chars"
accept_char_run(l::Lexer, valid::String) = accept_char_run(ch->ch in valid, l)

"Accept characters which `pred` evaluate to true. E.g. `accept_char_run(l, isdigit)`"
function accept_char_run(pred::Function, l::Lexer)
	while pred(peek_char(l))
        next_char(l)
    end
end

"Get lexeme that has been lexed thus far"
function lexeme(l::Lexer)
    if l.start > l.pos
        ""
    else
	    l.input[l.start:l.pos]
    end
end

"Send token of type `t` with lexeme `s` to channel `l.tokens`"
function emit_token(l::Lexer, t::TokenType, s::AbstractString)
    token = Token(t, s)
    put!(l.tokens, token)
    l.start = l.pos + 1
end

emit_token(l::Lexer, t::TokenType) = emit_token(l, t, lexeme(l))

"Skip the current token. E.g. because it is whitespace"
function ignore(l::Lexer)
	l.start = l.pos + 1
end

"Skip whitespace in input"
function ignore_whitespace(l::Lexer)
	while isspace(peek_char(l))
		next_char(l)
	end
	l.start = l.pos + 1
end

"Return this from a lexer state when there is an error"
function error(l::Lexer, error_msg::String)
	token = Token(ERROR, error_msg)
    put!(l.tokens, token)
    return lex_end
end

################### Scan Common Types ###################
"""
Advancing the position in the lexer input passed any number.
It means `lexeme(lexer)` will return a number.
To emit a number token you can just write:

    if scan_number(l)
        emit_token(l, NUMBER)
    end

The reason for doing it this way, is that it retains flexibility
in with which lexer state should be associated with lexing a number.
Several kinds of lexer will need to lex a number. So we want
reusable functions.
"""
function scan_number(l::Lexer)
	# leading sign is optional, but we'll accept it
	accept_char(l, "-+")

	# Could be a hex number, assume it is not first
	digits = "0123456789"
	if accept_char(l, "0") && accept_char(l, "xX")
		digits *= "abcdefABCDEF"
	end
	accept_char_run(l, digits)
	if accept_char(l, ".")
		accept_char_run(l, digits)
	end
	if accept_char(l, "eE")
		accept_char(l, "-+")
		accept_char_run(l, "0123456789")
	end
    return true
end

"""
Advancing the position in the lexer input passed any quoted string.
It means `lexeme(lexer)` will return a quoted string. Example:

    if scan_string(l)
        emit_token(l, STRING)
    end
"""
function scan_string(l::Lexer)
	if !accept_char(l, "\"")
        return false
    end
	while true
		ch = next_char(l)
        if ch == '\\'
            c = next_char(l)
            if c == EOFChar || c == '\n'
                return false
            end
		elseif ch == '"'
            break
		elseif ch == EOFChar
			return false
		end
	end
	return true
end

function scan_identifier(l::Lexer)
    ch = peek_char(l)
    if !isletter(ch)
        return false
    end

    while ch != EOFChar && isalnum(ch)
        next_char(l)
        ch = peek_char(l)
    end

    return true
end

################### Lexer Common ###################
"Marker for indicating there is no more input. Since we don't want to use nil in Julia"
function lex_end(l::Lexer)
	return lex_end
end

function lex(input::AbstractString, start::Function)
    l = Lexer(input)
    @async run(l, start)
    return l
end

function run(l::Lexer, start::Function)
    state = start
    while state != lex_end
        state = state(l)
    end
    close(l.tokens)
end

next_token(l::Lexer) = take!(l.tokens)
drain(l::Lexer) = collect(l.tokens)
