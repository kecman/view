#import "Basic";

#import "geometry";
#load "io.jai";

check_failure_terminates :: false;

check :: (a : $T, b : T, check_proc : (T, T)->bool, loc := #caller_location) -> bool {
    passed := check_proc(a, b);
    if !passed {
        print("Check failed at %:%\n", loc.fully_pathed_filename, loc.line_number);
        if check_failure_terminates exit(0);
    }
    return passed;
}

require :: (a : $T, b : T, check_proc : (T, T)->bool, loc := #caller_location) {
    passed := check_proc(a, b);
    if !passed {
        print("Require failed at %:%\n", loc.fully_pathed_filename, loc.line_number);
        exit(0);
    }
}

// @TODO make an `obj_polyline_soup` function and test it, and run tests using procedure notes
// @TODO perhaps this is simpler to implement with segment iterators etc
main :: () {
    dropped := "/home/matija/Dropbox/view/data/test-geometry/polyline_soup_2_000.obj";
    obj := load_obj(dropped);
    default_check :: (a,b)=>(a==b); 
    check(obj.segments.count, 9, default_check);
    check(obj.vertices.count, 10, default_check);

    soup2, success := to_Polyline_Soup2(obj);
    check(success, true, default_check);
    if !success print("Skipped file: '%' (only 2D polylines with constant z are supported)\n", dropped);


}

// this file should be compiled and run when we pass --test to build.jai function should be run
test_function :: () {
    // has a list of filenames and properties of the output we want to check e.g., num elements/coordinates etc
    // for each file, load it, parse it, check it

    print("called test_function");
} @test