Math :: #import "Math";

main :: () {
    a := Math.make_vector3(3, 3, 3);
    b := Math.make_vector3(1, 1, 1);
    // c := a - b; // Error: Attempt to use the binary operator '-', which is not defined in this scope for types (Vector3, Vector3).
    d := Math.operator-(a, b);
}