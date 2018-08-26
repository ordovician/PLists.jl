# PLists

A module for reading and writing OS X plists in ASCII format. This is the property list format that originated on NeXTSTEP. The binary and XML format commonly used on Mac today is presently not supported

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

## Installation
Upgraded to work with the Julia 1.0 package manager. Get into package mode on the Julia command line using the ']' key.

    pkg> add https://github.com/ordovician/EditorUtils.jl
    
