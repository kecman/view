/*

    Why is there no implicit cast for assert?

*/

#import "Basic";

main :: () {

    if_check :: (arg: $T) {
        b := cast(bool) arg;

        if arg {
            print("b is: %. It had better be true.\n", b);
        } else {
            print("b is: %. It had better be false.\n", b);
        }

        // assert(arg);  // Compile error "Error: Type mismatch. (wanted: bool; given: s64)"
    }
    
    if_check(0);
    // assert(0); // Compile error "Error: Type mismatch. (wanted: bool; given: s64)"
    // if_check(1);
    // if_check(cast(s16) -37);
    // if_check(69105.33);
    // if_check("Hello, Sailor!");
}