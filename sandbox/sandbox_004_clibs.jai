#import "Basic";

myfuncs_lib :: #foreign_library "libmyfuncs";

add_func :: (a: s32, b: s32) -> s32 #foreign myfuncs_lib;

main :: () {
    v := add_func(42, 43);
    print("hey. %\n", v);
}