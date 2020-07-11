export  parsexml,
        # Debug, remove later
        xmlparser, parse_node, parse_element

tagstrip(tag::AbstractString) = strip(tag, ['<', '>', '/'])

function match_closing_tag(n::ElementNode, t::Token)
    close_tagname = tagstrip(t.lexeme)
    if n.name != close_tagname
        error("opening tag '$(n.name)' does not match closing tag '$close_tagname'")
    end
end

function add_parsed_nodes!(parser::Parser, parent::ElementNode)
    t = peek_token(parser)
    while t.kind == BEGIN_TAG || t.kind == TEXT
        addchild!(parent, parse_node(parser))
        t = peek_token(parser)
    end
end

function add_parsed_attribute_nodes!(parser::Parser, parent::ElementNode)
    t = peek_token(parser)
    while t.kind == IDENT
        t = expect(parser, IDENT)
        name = t.lexeme
        expect(parser, EQUAL)
        t = expect(parser, STRING)
        value = t.lexeme
        parent[name] = value
        t = peek_token(parser)
    end
end

function parse_text(parser::Parser)
    t = expect(parser, TEXT)
    TextNode(t.lexeme)
end

function parse_element(parser::Parser)
    t = peek_token(parser)
    expect(parser, BEGIN_TAG)
    tagname = tagstrip(t.lexeme)
    n = ElementNode(tagname)

    t = peek_token(parser)
    while t.kind in [END_TAG, IDENT]
        if t.kind == END_TAG
            expect(parser, END_TAG)
            add_parsed_nodes!(parser, n)
        elseif t.kind == IDENT
            add_parsed_attribute_nodes!(parser, n)
        end
        t = peek_token(parser)
    end

    t = next_token(parser)
    if t.kind == CLOSE_TAG
        match_closing_tag(n, t)
    end

    if t.kind ∉ [CLOSE_TAG, END_AND_CLOSE_TAG]
        error("Element node needs to end with /> or </$(n.name)> not '$t'")
    end

    return n
end

function parse_node(parser::Parser)
    t = peek_token(parser)
    if t.kind == BEGIN_TAG
        parse_element(parser)::Node
    elseif t.kind == TEXT
        parse_text(parser)::Node
    else
        error("Had not expected token '$t' while looking for start of new XML node")
    end
end

xmlparser(s::AbstractString) = Parser(lex_xml(s))

function strip_xml_header(xmlstring::AbstractString, ignore_declaration::Bool)
    # Get the XML declaration. It is not part of the XML DOM, so we want
    # to exclude it.
    r = findfirst(r"<\?xml.*\?>", xmlstring)
    s = xmlstring # assume there is no XML declaration until proven otherwise
    if r == nothing
        ignore_declaration || @warn "Did not find any XML declaration such as <?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    else
        s = xmlstring[last(r)+1:end]
        # Check encoding used
        decl = xmlstring[r]
        m = match(r"encoding=\"([\w-]+)\"", decl)
        if isempty(m.captures)
            @warn "Could not determine encoding, will assume UTF-8"
        else
            encoding = m.captures[1]
            if uppercase(encoding) != "UTF-8"
                @warn "XML parser is not made to handle $encoding encoding. XML file should have UTF-8 encoding"
            end
        end
    end

    # Skip DOC type as we don't handle it
    r = findfirst(r"<!DOCTYPE[^>]+>", s)
    if r != nothing
        s = s[last(r)+1:end]
    end
    return s
end

"Parse a text string containing XML, and return an XML document object"
function parsexml(xmlstring::AbstractString; ignore_declaration=false)
    s = strip_xml_header(xmlstring, ignore_declaration)
    l = lex_xml(s)
    p = Parser(l)
    Document(parse_element(p))
end
