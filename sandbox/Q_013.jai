/*


This is not a bug, statement `i::int;` declares i to be a Type! similarly for type_const


*/

#import "Basic";

i :: int;
j : int;

Geometry_Type :: enum {
    POLYLINE :: 0;
    POLYGON  :: 1;
    MESH     :: 2;
}

Geometry :: struct {
    type_const :: Geometry_Type;
    type       :  Geometry_Type;
}

main :: () {
    a : Geometry;

    print("type_info:\n%\n%\n", <<type_info(type_of(i)), <<type_info(type_of(j)));
    print("type_info:\n%\n%\n", <<type_info(type_of(a.type)), <<type_info(type_of(a.type_const)));

    // Accessing the type as a mutable member works...
    if a.type == .POLYLINE print("Works\n");

    // ...but when I make type constant mis-typing copy Type_Info code and written two :'s rather than one, giving me confusing errors:

    // Error: Unary '.' dereferences only match to enum types, but here it is trying to match type 'Type'. 
    // if a.type_const == .POLYLINE print("Error\n");

    // Error: Type mismatch. (wanted: Type; given: Geometry_Type) 
    // if a.type_const == Geometry_Type.POLYLINE print("Error\n");
}
