export lex_xml

function lex_begin_tag(l::Lexer)
    if !accept_char(l, "<")
        return error(l, "XML tag must begin  with '<'")
    end
    
    if accept_char(l, "/")
        if scan_identifier(l) && accept_char(l, ">")            
            emit_token(l, CLOSE_TAG)
            return lex_xml
        else
           return error(l, "XML closing tag must have alphanumeric identifier and end with '>'") 
        end
    elseif scan_identifier(l)
        emit_token(l, BEGIN_TAG)
        if accept_char(l, ">")
            emit_token(l, END_TAG)
            return lex_xml
        else
           return lex_inside_tag 
        end
    else
        return error(l, "Encountered neither a open or closing tag")
    end
end

"lex an identifier such as a variable or function name"
function lex_attrib_ident(l::Lexer)
    scan_identifier(l)
    emit_token(l, IDENT)
    return lex_inside_tag
end

"Lex a string enclosed in \" quotes"
function lex_attrib_string(l::Lexer)
    if scan_string(l)
        emit_token(l, STRING)
        lex_inside_tag
    else
        error(l, "Not a valid quoted string")
    end
end

"Lex the text content between two tags. Includes whitespace"
function lex_text(l::Lexer)
    ch = peek_char(l)
    while ch ∉ ['<', '>', EOFChar]
        next_char(l)
        ch = peek_char(l)
    end
    emit_token(l, TEXT)
    return lex_xml
end

function lex_inside_tag(l::Lexer)
    while true
        ignore_whitespace(l)
    	ch = peek_char(l)
        
        if ch == '>'
            next_char(l)
            emit_token(l, END_TAG)
            return lex_xml
    	elseif ch == '/'
            if accept_char(l, "/") && accept_char(l, ">")
                emit_token(l, END_AND_CLOSE_TAG)
                return lex_xml
            else
                return error(l, "Not properly formed end and close tag")
            end
    	elseif ch == '"'
    		return lex_attrib_string
    	elseif isletter(ch)
    		return lex_attrib_ident
        elseif ch == '='
            next_char(l)
            emit_token(l, EQUAL)
            return lex_inside_tag
        else
            return error(l, "Don't know how to handle '$ch'")
    	end        
    end
end

function lex_xml(l::Lexer)
	while true
        ignore_whitespace(l)
    	ch = peek_char(l)

    	if ch == EOFChar
    		emit_token(l, EOF)
            return lex_end
    	elseif ch == '<'
            return lex_begin_tag
        else
           return lex_text 
        end
    end
end

function lex_xml(input::String)
    lex(input, lex_xml)
end
