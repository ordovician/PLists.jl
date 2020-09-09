# PLists

A package for reading XML files, NeXTSTEP property list files (plist), macOS plist files in XML format. The XML reader is intentionally kept simple for educatonal reasons, so only basic XML format can be parsed. However the package has the benefit of having no dependencies and being implemented purely in Julia.

## Working with XML

The examples directory contains some simple XML files which you can read with this parser. Here is an example of how you would read one of these files.

    julia> doc = readxml("note.xml");

    julia> r = root(doc);

    julia> ns = nodes(r);

    julia> xml(r)
    <note>
      <to>Batman</to>
      <from>Joker</from>
      <heading>Why so serious?</heading>
      <body>Haven't you ever heard of the healing power of laughter?</body>
    </note>

    julia> ns[1]

    (ElementNode "to"
      (TextNode "Batman"))

    julia> ns[2]

    (ElementNode "from"
      (TextNode "Joker"))

    julia> xml(ns[2])
    <from>Joker</from>

The DOM API has been modeled on the API used in [EzXML.jl](https://bicycle1885.github.io/EzXML.jl/latest/manual/). The key difference being that EzXML is a wrapper around a C/C++ XML parser while PLists has no dependencies.

## Working with NeXTSTEP PList Files

macOS was derived from the NeXTSTEP operating system, where the plist file format was used extensively for configuration files. It is very similar the JSON files although it came earlier. A couple of interesting differences is that it supports enum values and binary data which JSON doesn't support.

Example of plist ASCII format:

	{
	  Dogs = (
	    {
	      Name = "Scooby Doo";
	      Age = 43;
	      Colors = (Brown, Black);
	    }
	  );
      BinaryData = <0fbd77 1c2735ae>;
	}
	
    
The plists can be read and written with `readplist` and `writeplist` which are designed to be similar to be similar to `readcsv` and `writecsv`. Example:

    dict = readplist("example.plist")
    writeplist("file.plist", dict)
    
I based the implementation on the documentation of [Old-Style ASCII Property Lists](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/PropertyLists/OldStylePlists/OldStylePLists.html) on Apple's Developer pages. Here is an example from Apple:

    {
        AnimalSmells = { pig = piggish; lamb = lambish; worm = wormy; };
        AnimalSounds = { pig = oink; lamb = baa; worm = baa;
                        Lisa = "Why is the worm talking like a lamb?"; };
        AnimalColors = { pig = pink; lamb = black; worm = pink; };
    }
    
## maOS XML Based PList Files
In the test directory you can find the same file encoded both in NeXT and macOS XML format. Please note that current macOS plist files are binary encoded and not supported by this package. The `example.plist.xml` is a plist file in XML format. The contents of the file is:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
    <plist version="1.0">
    <dict>
        <key>Author</key>
        <string>William Shakespeare</string>
        <key>Lines</key>
        <array>
            <string>It is a tale told by an idiot,</string>
            <string>Full of sound and fury, signifying nothing.</string>
        </array>
        <key>Birthdate</key>
        <integer>1564</integer>
    </dict>
    </plist>
    
We can read this file with the following code:

    julia> dict = read_xml_plist("example.plist.xml")
    Dict{Any,Any} with 3 entries:
      "Author"    => "William Shakespeare"
      "Lines"     => ["It is a tale told by an idiot,", "Full of sound and fury, si…
      "Birthdate" => 1564

    julia> dict["Birthdate"]
    1564

    julia> lines = dict["Lines"]
    2-element Array{String,1}:
     "It is a tale told by an idiot,"
     "Full of sound and fury, signifying nothing."

    julia> lines[2]
    "Full of sound and fury, signifying nothing."

## Installation
Upgraded to work with the Julia 1.0 package manager. Get into package mode on the Julia command line using the ']' key.

    pkg> add https://github.com/ordovician/PLists.jl
    
