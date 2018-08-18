@testset "Lexer tests" begin
    @testset "Old PList Lexing" begin
        l = lex_plist("{eggs = spam; foo = (bar, \"foo bar\");}")
        @test next_token(l) == Token(LBRACE, "{")
        @test next_token(l) == Token(IDENT, "eggs")
        @test next_token(l) == Token(EQUAL, "=")
        @test next_token(l) == Token(IDENT, "spam")
        @test next_token(l) == Token(SEMICOLON, ";")
        @test next_token(l) == Token(IDENT, "foo")
        @test next_token(l) == Token(EQUAL, "=")
        @test next_token(l) == Token(LPAREN, "(")
        @test next_token(l) == Token(IDENT, "bar")
        @test next_token(l) == Token(COMMA, ",")
        @test next_token(l) == Token(STRING, "foo bar")
        @test next_token(l) == Token(RPAREN, ")")
        @test next_token(l) == Token(SEMICOLON, ";")
        @test next_token(l) == Token(RBRACE, "}")
    end
    
    @testset "Numbers and Identifiers Lexing" begin
        l = lex_plist("one 2 three 3 five")
        @test next_token(l) == Token(IDENT, "one")
        @test next_token(l) == Token(NUMBER, "2")
        @test next_token(l) == Token(IDENT, "three")
        @test next_token(l) == Token(NUMBER, "3")
        @test next_token(l) == Token(IDENT, "five")
    end
end
    
@testset "Parser tests" begin
    @testset "Numbers and Identifiers Parser" begin
        l = lex_plist("{eggs = spam; foo = (bar, \"foo bar\");}")
        p = Parser(l)
        @test peek_token_type(p) == LBRACE
        next_token(p)
        @test peek_token_type(p) == IDENT
        next_token(p)
        @test peek_token_type(p) == EQUAL
        next_token(p)
        @test peek_token_type(p) == IDENT
        next_token(p)
        @test peek_token_type(p) == SEMICOLON
        next_token(p)
        @test peek_token_type(p) == IDENT
        next_token(p)
        @test peek_token_type(p) == EQUAL
        next_token(p)
        @test peek_token_type(p) == LPAREN
        next_token(p)
        @test peek_token_type(p) == IDENT
        next_token(p)
        @test peek_token_type(p) == COMMA
        next_token(p)
        @test peek_token_type(p) == STRING
        next_token(p)
        @test peek_token_type(p) == RPAREN
        next_token(p)
        @test peek_token_type(p) == SEMICOLON
        next_token(p)
        @test peek_token_type(p) == RBRACE
        next_token(p)
        @test peek_token_type(p) == EOF
    
        # strange_tokens = token_producer("\"Dot(u Vector2D) float64\" \"()\$0\"")
        # @test pop!(strange_tokens) == Token(STRING, "Dot(u Vector2D) float64")
        # @test pop!(strange_tokens) == Token(STRING, "()\$0")
    end

    @testset "PList decoding tests" begin
        @test readplist_string("1234") == 1234
        @test readplist_string("foobar") == "foobar"
        @test readplist_string("(1, 2, 3, 4)") == [1, 2, 3, 4]
        @test readplist_string("(one, two, three)") == ["one", "two", "three"]
        @test readplist_string("{foo = bar;}") == Dict("foo" => "bar")
        @test readplist_string("{one = 1;}") == Dict("one" => 1)
        @test readplist_string("<0fbd77 1c2735ae>") == UInt8[0x0f, 0xbd, 0x77, 0x1c, 0x27, 0x35, 0xae]
        @test readplist_string("<ffff>") == UInt8[0xff, 0xff]
        @test readplist_string("<00 01 02 03>") == UInt8[0x00, 0x01, 0x02, 0x03]
        @test readplist_string("{bin = <abcdef>;}") == Dict("bin" => UInt8[0xab, 0xcd, 0xef])

        dict = readplist("example.plist")

        @test !isempty(dict)
        @test haskey(dict, "Dogs")
        @test length(dict["Dogs"][1]) == 3
        @test dict["Dogs"][1]["Name"] == "Scooby Doo"
        @test dict["Dogs"][1]["Age"] == 43
        @test dict["Dogs"][1]["Colors"] == ["Brown", "Black"]
        @test dict["BinaryData"] == UInt8[0x0f, 0xbd, 0x77, 0x1c, 0x27, 0x35, 0xae]
    end
end


@testset "PList encoding tests" begin
    @test writeplist_string(Dict()) == "{}"
    @test writeplist_string([]) == "()"
    @test writeplist_string("foobar") == "foobar"
    @test writeplist_string("foo bar") == "\"foo bar\""
    @test writeplist_string(1234) == "1234"
    @test writeplist_string([1, 2, 3, 4]) == "(1, 2, 3, 4)"
    @test writeplist_string(["one", "two", "three"]) == "(one, two, three)"
    @test writeplist_string(["first number", "second number"]) == "(\"first number\", \"second number\")"
    @test writeplist_string(Dict("foo" => "bar")) == "{foo = bar;}"
    @test writeplist_string(Dict("one" => 1)) == "{one = 1;}"

    @test writeplist_string([1, [2, 3], 4]) == "(1, (2, 3), 4)"
    @test writeplist_string(Dict("colors" => ["red", "green", "blue"])) == "{colors = (red, green, blue);}"
end

@testset "XML parser tests" begin
    @testset "Test Element Node" begin
        doc = parsexml("<key>Author</key>", ignore_declaration=true)
        @test hasroot(doc)
        r = root(doc)
        @test nodename(r) == "key"
        n = first(nodes(r))
        @test istext(n)
        @test nodecontent(n) == "Author"
        @test countnodes(r) == 1
    end
    
    @testset "Test Element Nodes Hierarchy" begin
        doc = parsexml("<numbers><one>en</one><two>to</two><three>tre</three></numbers>", ignore_declaration=true)
        @test hasroot(doc)
        r = root(doc)
        @test nodename(r) == "numbers"
        @test nodecontent(r) == "entotre"
        @test countnodes(r) == 3
        
        @test nodecontent(nodes(r)[1]) == "en"
        @test nodecontent(nodes(r)[2]) == "to"
        @test nodecontent(nodes(r)[3]) == "tre"
        
        @test nodename(nodes(r)[1]) == "one"
        @test nodename(nodes(r)[2]) == "two"
        @test nodename(nodes(r)[3]) == "three"
    end
    
    @testset "Test Small Example" begin
        doc = parsexml("""
        <primates>
            <genus name="Homo">
                <species name="sapiens">Human</species>
            </genus>
            <genus name="Pan">
                <species name="paniscus">Bonobo</species>
                <species name="troglodytes">Chimpanzee</species>
            </genus>
        </primates>
        """, ignore_declaration=true)
        primates = root(doc)
        @test nodename(primates) == "primates"
        genus = nodes(primates)
        @test countnodes(primates) == 2
        @test nodecontent(genus[1]) == "Human"
        homo_genus_attr = attributes(genus[1])
        homo_attr = first(homo_genus_attr)
        @test homo_attr.name == "name"
        @test homo_attr.value == "Homo"
    end
end

@testset "XML PList tests" begin
    @testset "PList decoding tests" begin
        dict = read_xml_plist("example.plist.xml")

        @test !isempty(dict)
        @test haskey(dict, "Author")
        @test dict["Author"] == "William Shakespeare"
        @test haskey(dict, "Lines")
        @test length(dict["Lines"]) == 2
        @test dict["Lines"][1]  == "It is a tale told by an idiot,"
        @test dict["Lines"][2]  == "Full of sound and fury, signifying nothing."
        @test dict["Birthdate"] == 1564
    end
    
    @testset "Simple PList tests" begin
            dict = read_xml_plist_string(
            """
            <plist version="1.0">
            <dict>
                <key>egg</key>
                <string>spam</string>
                <key>numbers</key>
                <array>
                    <string>one</string>
                    <string>two</string>
                </array>
            </dict>
            </plist>""")
            @test dict["egg"] == "spam"
            @test dict["numbers"][1] == "one"
            @test dict["numbers"][2] == "two"
    end
    
    @testset "Test PList parsing independent from XML parsing" begin
        root = ElementNode("plist")
        root["version"] = "1.0"
        strings  = Node[ElementNode("string", "one"), ElementNode("string", "two")] 
        children = Node[ElementNode("key", "egg"), 
                        ElementNode("string", "spam"),
                        ElementNode("key", "numbers"),
                        ElementNode("array", strings)]
        addchild!(root, ElementNode("dict", children))
        
        dict = PLists.parse_obj(root)
        @test dict["egg"] == "spam"
        @test dict["numbers"][1] == "one"
        @test dict["numbers"][2] == "two"
    end
end