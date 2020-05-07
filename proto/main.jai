#import "Basic";

// See examples/snake/src/obj_loader.jai

// Idea is:
// With a CLI parameter parse interface.proto and generate interface.jai
// Write a program that uses the interface?

// Make a youtube video about how things works to post by your personal projects

// Text_File_Handler is a struct with associated procedures which are free functions
// that take pointers to the Text_File_Handler

// Maybe a polyline debugger? where polyline was saved as proto
// Make a gvs clone in Jai?

// TODO
// Load the proto file (at compile time)
// Make the parser
// Make a simple proto file and parse that
// How to do interfaces in this language?
// Need to write some kind of networking library, perhaps port a simple C++ one

// Protobuf to Jai compiler.
//
// proto3 language guide descibes the syntax in EBNF, use this to write the parser/lexer/tokenizer?
//   https://developers.google.com/protocol-buffers/docs/proto3
// C++ generated code guide describes the C++ created for singular fields/messsages etc
//   https://developers.google.com/protocol-buffers/docs/reference/cpp-generated
// Encoding documentation explains how to serialise/deserialise protobuf messages
//   https://developers.google.com/protocol-buffers/docs/encoding


main :: () {
    a, b, c, d, e : s64 = 0x0, 0x1, 0x2, 0x3, 0x4;

    print("% % % % %\n\n", a, b, c, d, e);
    print("% % \n\n", formatInt(15, base=16), formatInt(15, base=2));

    // Return an varint representing `i`:
    // 
    to_varint :: (i : s64) {
        // hex is base16
        mask := 0x00_00_00_00; // 4 bytes = 32 bits
        mask := 0x00_00_00_00_00_00_00_00; // 8 bytes = 32 bits
    }
}

#run main();