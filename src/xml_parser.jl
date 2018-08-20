# NOTE: The interface has been modeled as far as possible on the EzXML.jl XML
# parser. This is so EzXML can be a drop in replacement. The benefits of this
# parser over EzXML is that it has no dependencies. It is all pure Julia code.
# The downside is that it just supports the most common XML features
import Base: setindex!, getindex, show

export  Node, Document, ElementNode, TextNode, AttributeNode,
        nodename, iselement, istext, isattribute, hasroot,
        nodecontent, 
        countnodes, countattributes,
        nodes, elements, textnodes, attributes, eachattribute,
        root, setroot!,
        addchild!, addchildren!, addelement!,
        parsexml,
        # Debug, remove later
        xmlparser, parse_node, parse_element

"All nodes in XML DOM is some type of Node."
abstract type Node end

"Top level of an XML DOM"
mutable struct Document
    rootnode::Nullable{Node}
end

"Top level of an XML DOM"
function Document()
    Document(Nullable{Node}())
end

"""
Represents an attribute inside a tag.

# Example
Here `class` and `name` are examples of attributs belonging to parent node
`widget`.

    <widget class="QCheckBox" name="checkBox">
"""
mutable struct AttributeNode <: Node
    # parent::Node
    name::String
    value::String 
end

"XML Node which can contain attributes and child nodes"
mutable struct ElementNode <: Node
    # parent::Node
    name::String
    attributes::Vector{AttributeNode}
    children::Vector{Node}
end

function ElementNode(name::AbstractString)
    ElementNode(name, AttributeNode[], Node[])
end

"Represents the text found between two tags. E.g. in `<foo>bar</foo>` bar is the `TextNode`"
mutable struct TextNode <: Node
    # parent::Node
    content::String
end

"Creates an element node named `name` with a text node containing text `value`"
function ElementNode(name::AbstractString, value::AbstractString)
    ElementNode(name, AttributeNode[], Node[TextNode(value)])
end

"Element node with children `nodes`"
function ElementNode(name::AbstractString, nodes::Array{T}) where T <: Node
    ElementNode(name, AttributeNode[], nodes)
end

"""Element node with attributes given like `ElementNode("widget", ["class"=>class, "name"=>name])`"""
function ElementNode(name::AbstractString, attributes::Vector{Pair{String, String}})
    ElementNode(name, [AttributeNode(name, value) for (name, value) in attributes], Node[])
end

function getindex(n::ElementNode, key::String)
    for m in n.attributes
        if m.name == key
            return m.value
        end
    end
    error("No attribute with key $key exist")
end

function setindex!(n::ElementNode, value::String, key::String)
    ii = find(m->m.name == key, n.attributes)
    if isempty(ii)
        push!(n.attributes, AttributeNode(key, value))
    else
        n.attributes[ii[1]] = AttributeNode(key, value)
    end
end

"Get all child nodes under node `n`"
nodes(n::Node) = Node[]
nodes(n::ElementNode) = n.children

"Get all elements under node `n`"
elements(n::Node) = ElementNode[]
elements(n::ElementNode) = filter(iselement, nodes(n))

textnodes(n::Node) = TextNode[]
textnodes(n::ElementNode) = filter(istext, nodes(n))

"Get an array of attributes under node `n`"
attributes(n::Node) = AttributeNode[]
attributes(n::ElementNode) = n.attributes

"Gets a dictionary of attributes meant to use in a for loop for iteration"
eachattribute(n::Node) = AttributeNode[]
eachattribute(n::ElementNode) = n.attributes

"For an XML tag looking like `<foo>bar</foo>` the `nodename` would be foo"
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

"Get content of all text nodes under `n`"
nodecontent(n::TextNode) = n.content
nodecontent(n::Node) = join(map(nodecontent, nodes(n)))

function addelement!(parent::Node, name::AbstractString)
    child = ElementNode(name)
    addchild!(parent, child)
    child
end

"Add `child` node to `parent` node"
function addchild!(parent::Node, child::Node)
    error("Can't add children to nodes of type $(typeof(parent))")
end

addchild!(parent::ElementNode, child::Node) = push!(parent.children, child)

"""
    addchildren(parent, children::Vector{Pair{String, String}})
    
A convenience function for easily adding child elements to a parent node `p`.

# Examples

    addchildren!(node, ["x" => "10", "y" => "20"])
"""
function addchildren!(p::Node, children::Vector{Pair{String, String}})
    for child in children
        addchild!(p, ElementNode(first(child), last(child)))
    end
end

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
    r = search(xmlstring, r"<\?xml.*\?>")
    s = xmlstring # assume there is no XML declaration until proven otherwise
    if isempty(r)
        ignore_declaration || warn("Did not find any XML declaration such as <?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    else
        s = xmlstring[last(r)+1:end]
        # Check encoding used
        decl = xmlstring[r]
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
    
    # Skip DOC type as we don't handle it
    r = search(s, r"<!DOCTYPE[^>]+>")
    if !isempty(r)
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

function show(io::IO, doc::Document)
  if hasroot(doc)
    show(io, root(doc), 1)
  else
    print(io, "Document()")
  end
end

function show(io::IO, n::TextNode)
    print(io, n.content)
end

function show(io::IO, n::Node, depth::Integer = 0)
    print(io, "Unknown node type")
end

function show(io::IO, n::AttributeNode)
   print(io, n.name, "=\"", n.value,"\"") 
end

function show(io::IO, n::TextNode, depth::Integer)
    print(io, "  "^depth)
    println(io, n.content)
end

function show(io::IO, parent::ElementNode, depth::Integer = 0)
    print(io, "  "^depth)
    
    tag = nodename(parent)
    print(io, "<$tag")
    attrs = map(x -> x.name * "=\"$(x.value)\"", attributes(parent))
    attr_str = join(attrs, " ")
    
    if !isempty(attr_str)
        print(io, " ", attr_str)
    end
    
    children = nodes(parent)
    len = length(children)

    if len == 0 || (len == 1 && istext(first(children)))
        print(io, ">")
        for n in children show(io, n) end
    else
        println(io, ">")
        for n in children
            show(io, n, depth + 1)
        end
        print(io, "  "^depth)
    end
    println(io, "</$tag>")
end