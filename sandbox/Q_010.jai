Math :: #import "My_Math";
#import "My_Math_Operators";

main :: () {
    a := Math.make_vector3(3, 3, 3);
    b := Math.make_vector3(1, 1, 1);
    c := a - b;
}