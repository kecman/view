#import "Basic";

main :: () {
    t : Type : int;    // OK!
    // t : Type = int; // ERROR "Error: When trying to evaluate a constant Type, a non-constant declaration was encountered."
    i : t = 54;
    print("i = %\n", i);
}