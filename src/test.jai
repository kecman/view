check_failure_terminates :: false;

check :: (a : $T, b : T, check_proc : (T, T)->bool = (a,b)=>(a==b), loc := #caller_location) -> bool {
    passed := check_proc(a, b);
    if !passed {
        print("Check failed at %:%. Wanted %, got %\n", loc.fully_pathed_filename, loc.line_number, a, b);
        if check_failure_terminates exit(0);
    }
    return passed;
}

require :: (a : $T, b : T, check_proc : (T, T)->bool = (a,b)=>(a==b), loc := #caller_location) {
    passed := check_proc(a, b);
    if !passed {
        print("Require failed at %:%. Wanted %, got %\n", loc.fully_pathed_filename, loc.line_number, a, b);
        exit(0);
    }
}

// @TODO make an `obj_polyline_soup` function and test it, and run tests using procedure notes
// @TODO perhaps this is simpler to implement with segment iterators etc
main :: () {
    filename :: "/home/matija/Dropbox/garage/data/test-geometry/polyline_soup_2_000.obj";
    obj := load_obj(filename);

    check(obj.indices.count, 18);
    check(obj.positions.count, 10);

    soup2, success := to_Polyline_Soup2(obj);
    check(success, true);
    if !success print("Skipped file: '%' (only 2D polylines with constant z are supported)\n", filename);
}

// // this file should be compiled and run when we pass --test to build.jai function should be run
// test_function :: () {
//     // has a list of filenames and properties of the output we want to check e.g., num elements/coordinates etc
//     // for each file, load it, parse it, check it
//     print("called test_function");
// } @test

#scope_file

#import "geometry" (USE_GRAPHICS = false);
#load "io_obj.jai";
#load "mesh_utils.jai";

#import "Basic";
#import "Compiler";
