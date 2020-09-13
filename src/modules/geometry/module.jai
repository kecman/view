#load "axis_box.jai";
#load "polyline.jai";
#load "mesh.jai";
#load "rendering.jai";

to_radians :: (degrees : float) -> float {
    scale :: PI / 180;
    return degrees * scale;
}

#scope_module

check_vector :: (T : Type, loc := #caller_location) {
    dim := vector_dimension(T);
    if dim < 2 || dim > 3 {
        compiler_report_error(loc.fully_pathed_filename, loc.line_number, 0, "Expected Vector2 or Vector3");
    }
}

vector_dimension :: (T : Type, loc := #caller_location) -> int {
    if T == Vector2 return 2;
    if T == Vector3 return 3;
    compiler_report_error(loc.fully_pathed_filename, loc.line_number, 0, "Expected Vector2 or Vector3");
    return -1;
}

#import "Math";