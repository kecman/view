#import "Basic";

// Goal
//
// - Parse interface.proto (see examples/snake/src/obj_loader.jai) and generate interface.jai
// - Decode protobuf binary messages from disk and deserialise into interface.jai datastructures
// - Write a program that uses the interface e.g., GVS server? polyline debugger? eventually jaiui for engine?
// - Write some kind of networking library (just port a simple C++ one?)

// Tasks
//
// - Load the proto file (at compile time)
// - Make the parser
// - Make a simple proto file and parse that
// - How to do interfaces in this language?

// Ideas
//
// - Youtube videos presenting personal projects

// Notes
//
// - proto3 language guide descibes the syntax in EBNF, use this to write the parser/lexer/tokenizer? https://developers.google.com/protocol-buffers/docs/proto3
// - C++ generated code guide describes the C++ created for singular fields/messsages etc https://developers.google.com/protocol-buffers/docs/reference/cpp-generated
// - Encoding documentation explains how to serialise/deserialise protobuf messages https://developers.google.com/protocol-buffers/docs/encoding
// - Google Protocol Buffers, for positive numbers, uses what they call Varint encoding, where there is a sentinel: numbers are stored in little-endian format, 7 bits per byte, and the most-significant bit is 0 for the last byte and 1 for all other bytes.

#if true {

zigzag_encode :: (value : $T) -> T
#modify { // @Question: How do I make this a reusable function?
    if T.type == .INTEGER {
        info_integer := cast(*Type_Info_Integer) T;
        if info_integer.signed {
            return; // Accept signed integers
        }
    } else {
        T = null; // Reject anything else
    }
}
{
    nbits :: size_of(T) * 8;
    return (value << 1) ^ (value >> (nbits - 1));
}

zigzag_decode :: (i : $T) -> T
#modify { // @Duplication
    if T.type == .INTEGER {
        info_integer := cast(*Type_Info_Integer) T;
        if info_integer.signed {
            return; // Accept signed integers
        }
    } else {
        T = null; // Reject anything else
    }
}
{ return (i >> 1) ^ -(i & 1); }

} else {

zigzag_encode :: (i : s32) -> s32 { return (i << 1) ^ (i >> 31); }
zigzag_encode :: (i : s64) -> s64 { return (i << 1) ^ (i >> 63); }
zigzag_decode :: (i : s32) -> s32 { return (i >> 1) ^ -(i & 1); }
zigzag_decode :: (i : s64) -> s64 { return (i >> 1) ^ -(i & 1); }

}

test_zigzag :: () {
    // @Incomplete Look up upb (mu protocol buffers, in the third party folder of the grpc repo, they have tests and code you can port for encoding/decoding)
    for test : {:s8: 0, -1, 1, 2, -2, 1<<6, -(1<<6)} {
        encoded := zigzag_encode(test);
        decoded := zigzag_decode(encoded);
        print("input = %, encoded = %, roundtrip = %\n", test, encoded, decoded);
        // print("input = %, encoded = %, roundtrip = %\n", formatInt(test, base=2, minimum_digits=32), formatInt(encoded, base=2, minimum_digits=32), formatInt(decoded, base=2, minimum_digits=32));
    }
}

main :: () {
    test_zigzag();
}

// #run main();