export  lex_number, lex_string, lex_identifier, lex_hexbinary,
        lex_basic

"Lex a number. Could be hexadecimal, scientific or start with +-"
function lex_number(l::Lexer)
    scan_number(l)
    emit_token(l, NUMBER)
    lex_basic
end

function lex_hexbinary(l::Lexer)
    accept_char(l, "<")
    accept_char_run(l) do ch
        isxdigit(ch) || isspace(ch)
    end
    if accept_char(l, ">")
        emit_token(l, HEXBINARY, filter(isxdigit, lexeme(l)))
    else
        return error(l, "Hexadecimal data must end with >")
    end
    return lex_basic
end

"Lex a string enclosed in \" quotes"
function lex_string(l::Lexer)
    if scan_string(l)
        emit_token(l, STRING)
        lex_basic
    else
        error(l, "Not a valid quoted string")
    end
end

"lex an identifier such as a variable or function name"
function lex_identifier(l::Lexer)
    scan_identifier(l)
    emit_token(l, IDENT)
    return lex_basic
end

function lex_basic(l::Lexer)
	while true
        ignore_whitespace(l)
    	ch = peek_char(l)

    	if ch == EOFChar
    		emit_token(l, EOF)
            return lex_end
    	elseif ch in "{}(),=;"
    		next_char(l)
    		emit_token(l, TokenType(ch))
    	elseif isdigit(ch) || ch in "-+"
    		return lex_number
    	elseif ch == '"'
    		return lex_string
    	elseif isalpha(ch)
    		return lex_identifier
        elseif ch == '<'
            return lex_hexbinary
    	end
    end
end
