import Base: show

export xml

####### Show s-expression ###########
function show(io::IO, doc::Document)
    print(io, "(Document")
    if hasroot(doc)
        show(io, root(doc), 1)
    else
        print(io, ")")
    end
end

function show(io::IO, p::Node, depth::Integer = 0)
    println(io)
    print(io, "  "^depth)
    print(io, "(", typeof(p), " \"")
    print(io, istext(p) ? nodecontent(p) : nodename(p))
    print(io, "\"")
    attrs = attributes(p)
    if !isempty(attrs)
       for a in attrs
          show(io, a, depth + 1) 
       end 
    end
    
    children = nodes(p)
    if isempty(children)
        print(io, ")")
    else
        # println(io)
        for n in children
            show(io, n, depth + 1)
        end
        # print(io, "  "^depth)
        print(io, ")")
    end
end

function show(io::IO, n::AttributeNode, depth::Integer = 0)
    println(io)
    print(io, "  "^depth)
    print(io, "(", typeof(n), " ")
    print(io, "\"", n.name, "\" = ", "\"", n.value, "\")")    
end

####### XML ###########
xml(node) = xml(stdout, node)

function xml(io::IO, doc::Document)
    if hasroot(doc)
        xml(io, root(doc), 1)
    else
        print(io, "Document()")
    end
end

function xml(io::IO, n::TextNode)
    print(io, n.content)
end

function xml(io::IO, n::Node, depth::Integer = 0)
    print(io, "Unknown node type")
end

function xml(io::IO, n::AttributeNode)
   print(io, n.name, "=\"", n.value,"\"")
end

function xml(io::IO, n::TextNode, depth::Integer)
    print(io, "  "^depth)
    println(io, n.content)
end

function xml(io::IO, parent::ElementNode, depth::Integer = 0)
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

    if len == 0
        println(io, "/>")
    elseif len == 1 && istext(first(children))
        print(io, ">")
        for n in children xml(io, n) end
    else
        println(io, ">")
        for n in children
            xml(io, n, depth + 1)
        end
        print(io, "  "^depth)
    end
    
    if len != 0
        println(io, "</$tag>")
    end
end
