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
