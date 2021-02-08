#module_parameters(USE_GRAPHICS := true);

#load "axis_box.jai";
#load "polyline.jai";
#load "polygon.jai";
#load "mesh.jai";

to_radians :: (degrees : float) -> float {
    scale :: PI / 180;
    return degrees * scale;
}

to_degrees :: (radians : float) -> float {
    scale :: 180 / PI;
    return radians * scale;
}

#scope_module

ensure_2d_or_3d :: (T : Type, loc := #caller_location) {
    dim := dimension_of(T);
    if dim < 2 || dim > 3 {
        compiler_report(loc.fully_pathed_filename, loc.line_number, 0, tprint("Expected Vector2 or Vector3, got %", T));
    }
}

// Returns a signed int so we can write dim-1 in loops and things just work
dimension_of :: (T : Type, loc := #caller_location) -> int {
    if T == Vector2 return 2;
    if T == Vector3 return 3;
    compiler_report(loc.fully_pathed_filename, loc.line_number, 0, tprint("Expected Vector2 or Vector3, got %", T));
    return -1;
}