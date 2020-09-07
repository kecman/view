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

load_obj :: (filename : string, result : **Mesh) {

    if !<<result {
        <<result = New(Mesh);
    }

    handler: Text_File_Handler;
    handler.do_version_number = false;
    defer deinit(*handler);

    start_file(*handler, "load_obj", filename, "load_obj_polyine2", false);
    if handler.failed {
        print("Error (%:%): Unable to find my own executable?!\n", #file, #line); // @Cleanup proper logging
        exit(1);
    }

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
            case "#"; // Ignore comments
            case "v";
                vertex, dim := parse_upto_3d(*handler, rhs);
                if dim == -1 || dim == 1 {
                    error(handler, tprint("Expected 2d or 3d vertex coordinates, got dim=%.\n", dim)); // @Incomplete test this
                    continue;
                }
                array_add(*(<<result).vertices, vertex);
            case "vn"; // @Incomplete
            case "vt"; // @Incomplete
            case "l";
                segment, dim := parse_upto_3d(*handler, rhs);
                if dim != 2 {
                    error(handler, "Expected a segment connecting two vertices.\n");
                    continue;
                }

                if (<<result).geometry_format == .UNKNOWN {
                    (<<result).geometry_format = .LINES;
                } else if (<<result).geometry_format != .LINES {
                    error(handler, "Expected consistent geometry format, got %, wanted %.\n", Geometry_Format.LINES, (<<result).geometry_format);
                    continue;
                }

                // obj indices are 1-based
                array_add(*(<<result).indices, cast(u32)segment.x - 1);
                array_add(*(<<result).indices, cast(u32)segment.y - 1);
            case "f"; // @Incomplete
            case;
                error(handler, "Unexpected '%'.\n", rhs);
                continue;
        }
    }

    // for result.vertices print("vertices: %\n", it);
    // for result.indices print("indices: %\n", it);
}

// FIXME
// FIXME
// FIXME
// FIXME
// FIXME
// FIXME
// FIXME
// FIXME
// FIXME
// FIXME
// FIXME
// FIXME

to_Mesh :: (shape : Polyline_Soup2, mesh : **Mesh) {
    assert(<<mesh != null);

    index := 0;
    for polyline : shape.polylines {
        for point : polyline.points {
            array_add(*(<<mesh).vertices, make_vector3(point.x, point.y, 0));
            array_add(*(<<mesh).indices, xx index);
            index += 1;
        }
    }
}

// TODO Make APIs consistent: pass in the polying soup memory to fill
to_Polyline_Soup2 :: (mesh : Mesh) -> Polyline_Soup2, bool #must {
    result : Polyline_Soup2;

    if mesh.geometry_format != .LINES || mesh.indices.count < 2 || mesh.vertices.count == 0 {
        return result, false;
    }

    for mesh.vertices {
        if it.z != mesh.vertices[0].z {
            return result, false; // Not a 2D shape in the xy-plane
        }
    }

    // @Cleanup Implement a segment iterator?

    Segment :: struct {
        from_index : int = ---;
        to_index : int = ---;
        from_point : Vector2 = ---;
        to_point : Vector2 = ---;
    }

    get_segment :: (mesh : Mesh, segment_index : int) -> Segment {
        assert(2 * segment_index + 1 < mesh.indices.count);

        segment : Segment;
        segment.from_index = mesh.indices[2 * segment_index];
        segment.to_index   = mesh.indices[2 * segment_index + 1];
        segment.from_point = mesh.vertices[segment.from_index].xy;
        segment.to_point   = mesh.vertices[segment.to_index].xy;
        return segment;
    }

    segment_index := 0;

    segment := get_segment(mesh, segment_index);
    polyline_start_index := segment.from_index;
    polyline := array_add(*result.polylines);
    array_add(*polyline.points, segment.from_point);

    while true {
        segment := get_segment(mesh, segment_index);
        array_add(*polyline.points, segment.to_point);

        segment_index += 1;
        if 2 * segment_index + 1 >= mesh.indices.count break;

        if segment.to_index == polyline_start_index {
            segment := get_segment(mesh, segment_index);
            polyline_start_index = segment.from_index;
            polyline = array_add(*result.polylines);
            array_add(*polyline.points, segment.from_point);
        }
    }

    return result, true;
}

#scope_file

#import "Text_File_Handler";
#import "Basic";
#import "String";
#import "Math";

#import "geometry";