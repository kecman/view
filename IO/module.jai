geom :: #import "Geom";


// Collect the verts, lines, faces etc, and decide what the type of the thing was at the end
// ex1. All verts, l with xy only and no z, or const z => polyline|polylinesoup
// Probably polyline2 should have a z height too

Vector2i :: struct {
    x, y: int;

#place x;
    component: [2] float = ---;
}

make_vector2i :: (x : int, y : int) -> Vector2i {
    v: Vector2i = ---;
    v.x, v.y = x, y;
    return v;
}

Vector3i :: struct {
    x, y, z: int;

#place x;
    xy: Vector2i = ---;
#place y;
    yz: Vector2i = ---;

#place x;
    component: [3] int = ---;
}

make_vector3i :: (x : int, y : int, z : int) -> Vector3i {
    v: Vector3i = ---;
    v.x, v.y, v.z = x, y, z;
    return v;
}

Obj :: struct {
    vertices :  [..] Vector3;
    normals :   [..] Vector3;
    segments :  [..] Vector2i;
    triangles : [..] Vector3i;
    polygons :  [..][..] int;
}

load_obj :: (filename : string) -> Obj #must {

    handler: Text_File_Handler;
    handler.do_version_number = false;
    defer deinit(*handler);

    start_file(*handler, "load_obj", filename, "load_obj_polyine2", false);
    if handler.failed {
        print("Error (%:%): Unable to find my own executable?!\n", #file, #line); // @Cleanup proper logging
        exit(1);
    }

    obj : Obj;

    while true {
        line, found := consume_next_line(*handler);
        if !found break;

        key_name, rhs := break_by_spaces(line);
        if !rhs {
            error(handler, "Expected a space after the key specifier.\n");
            continue;
        }

        // @TODO Make this nd and maybe also pass the string_to_number function (consider using procedure_of_call?)
        parse_upto_3d :: (handler : *Text_File_Handler, str : string) -> (vector : Vector3 #must, dim : int) {
            vector : Vector3;
            str_x, str_yz := break_by_spaces(str);
            vector.x = string_to_float(str_x);
            if str_yz {
                str_y, str_z := break_by_spaces(str_yz);
                vector.y = string_to_float(str_y);
                if str_z {
                    _, expect_empty := break_by_spaces(str_z);
                    vector.z = string_to_float(str_z);
                    if expect_empty {
                        return vector, -1;
                    }
                    return vector, 3;
                }
                return vector, 2;
            }
            return vector, 1;
        }

        if key_name == {
            case "v";
                vertex, dim := parse_upto_3d(*handler, rhs);
                if dim == -1 || dim == 1 {
                    error(handler, tprint("Expected 2d or 3d vertex coordinates, got dim=%.\n", dim)); // @Incomplete test this
                    continue;
                }
                array_add(*obj.vertices, vertex);
            case "vn"; // @Incomplete
            case "vt"; // @Incomplete
            case "l";
                segment, dim := parse_upto_3d(*handler, rhs);
                if dim != 2 {
                    error(handler, "Expected a segment connecting two vertices.\n");
                    continue;
                }
                array_add(*obj.segments, make_vector2i(xx segment.x, xx segment.y));
            case "f"; // @Incomplete
            case;
                print("found unknown: %\n", rhs);
                error(handler, "Unexpected '%'.\n", rhs);
                continue;
        }
    }

    // for obj.vertices print("vertices: %\n", it);
    // for obj.segments print("segments: %\n", it);

    return obj;
}

#scope_file

#import "Text_File_Handler";
#import "Basic";
#import "System";  // To get the executable's path.
#import "String";
#import "Math";