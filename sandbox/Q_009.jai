#load "load_scope_test.jai";
#import "Basic";
main :: () {
    a : Math_In_Scope_Export.Vector3; // works, as expected
    print("I can see %\n", a); // works, as expected
    print("I can see %\n", variable_in_scope_export); // works, as expected
    // print("I can see %\n", variable_in_scope_file); // uncommenting this gives an error, as expected
    // b : Math_In_Scope_File.Vector3; // uncommenting this gives an error, as expected
    c : Vector3; // works without a import name, but hmmm, maybe this is surprising
}