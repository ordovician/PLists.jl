# NOTE: The interface has been modeled as far as possible on the EzXML.jl XML
# parser. This is so EzXML can be a drop in replacement. The benefits of this
# parser over EzXML is that it has no dependencies. It is all pure Julia code.
# The downside is that it just supports the most common XML features
import Base: setindex!, getindex

export  Node, Document, ElementNode, TextNode, AttributeNode,
        nodename, iselement, istext, isattribute, hasroot, 
        countnodes, countattributes,
        nodes, elements, attributes, eachattribute,
        root, setroot!,
        addchild!, addelement!,
        parsexml,
        # Debug, remove later
        xmlparser, parse_node, parse_element

"All nodes in XML DOM is some type of Node."
abstract type Node end

mutable struct Document
    rootnode::Nullable{Node}
end

"Top level of an XML DOM"
function Document()
    Document(Nullable{Node}())
end

"XML Node which can contain attributes and child nodes"
mutable struct ElementNode <: Node
    # parent::Node
    name::String
    attributes::Dict{String, String}
    children::Vector{Node}
end

function ElementNode(name::AbstractString)
    ElementNode(name, Dict{String, String}(), Node[])
end

"Represents the text found between two tags. E.g. in `<foo>bar</foo>` bar is the `TextNode`"
mutable struct TextNode <: Node
    # parent::Node
    content::String
end

mutable struct AttributeNode <: Node
    # parent::Node
    name::String
    value::String 
end

getindex(n::ElementNode, key::String) = n.attributes[key]
setindex!(n::ElementNode, value::String, key::String) = n.attributes[key] = value

"Get all child nodes under node `n`"
nodes(n::Node) = Node[]
nodes(n::ElementNode) = n.children

"Get all elements under node `n`"
elements(n::Node) = ElementNode[]
elements(n::ElementNode) = filter(iselement, nodes(n))

"Get an array of attributes under node `n`"
attributes(n::Node) = AttributeNode[]
attributes(n::ElementNode) = [AttributeNode(name, value) for (name, value) in n.attributes]

"Gets a dictionary of attributes meant to use in a for loop for iteration"
eachattribute(n::Node) = Dict{String, String}()
eachattribute(n::ElementNode) = n.attributes

nodename(n::Node) = ""
nodename(n::TextNode) = "text"
nodename(n::ElementNode) = n.name

"Check if node is an element node. Element nodes can contain child nodes"
iselement(n::Node) = false
iselement(n::ElementNode) = true

"Check if node is a text node. Text nodes represents the text you find between XML tags."
istext(n::Node) = false
istext(n::TextNode) = true

"Check if node is an attribute node. Attributes are on the form `name = \"value\"`"
isattribute(n::Node) = false
isattribute(n::AttributeNode) = true

"Number of child nodes"
countnodes(n::Node) = 0
countnodes(n::ElementNode) = length(n.children)

"Number of attributes. Typically onlye element nodes have attributes"
countattributes(n::Node) = 0
countattributes(n::ElementNode) = length(n.attributes)

"Check if a root node has been set of XML document"
hasroot(doc::Document) = !isnull(doc.rootnode)

"Get root node. Make sure you check if it exists first with `hasroot(n)`"
root(n::Document) = get(n.rootnode)
setroot!(n::Document) = n.rootnode = Nullable(n)

function addelement!(parent::Node, name::AbstractString)
    child = ElementNode(name)
    addchild!(parent, child)
    child
end

function addchild!(parent::Node, child::Node)
    error("Can't add children to nodes of type $(typeof(parent))")
end

addchild!(parent::ElementNode, child::Node) = push!(parent.children, child)

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

"Parse a text string containing XML, and return an XML document object"
function parsexml(xmlstring::AbstractString)
    # Get the XML declaration. It is not part of the XML DOM, so we want
    # to exclude it.
    r = search(xmlstring, r"<\?xml.*\?>")
    s = xmlstring # assume there is no XML declaration until proven otherwise
    if isempty(r)
        warn("Did not find any XML declaration such as <?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    else
        s = xmlstring[last(r)+1:end]
        # Check encoding used
        decl = s[r]
        m = match(r"encoding=\"([\w-]+)\"", decl)
        if isempty(m.captures)
            warn("Could not determine encoding, will assume UTF-8")
        else
            encoding = m.captures[1]
            if uppercase(encoding) != "UTF-8"
                warn("XML parser is not made to handle $encoding encoding. XML file should have UTF-8 encoding")
            end
        end
    end
    l = lex_xml(s)
    p = Parser(l)
    Document(parse_element(p))
end
