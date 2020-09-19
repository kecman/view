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

load_obj :: (filename : string) -> Mesh {

    result : Mesh;

    handler: Text_File_Handler;
    handler.do_version_number = false;
    defer deinit(*handler);

    start_file(*handler, "load_obj", filename, "load_obj", false);
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
                array_add(*result.vertices, vertex);
            case "vn"; // @Incomplete
            case "vt"; // @Incomplete
            case "l";
                segment, dim := parse_upto_3d(*handler, rhs);
                if dim != 2 {
                    error(handler, "Expected a segment connecting two vertices.\n");
                    continue;
                }

                if result.geometry_format == .UNKNOWN {
                    result.geometry_format = .LINES;
                } else if result.geometry_format != .LINES {
                    error(handler, "Expected consistent geometry format, got %, wanted %.\n", Geometry_Format.LINES, result.geometry_format);
                    continue;
                }

                // obj indices are 1-based
                array_add(*result.indices, cast(u32)segment.x - 1);
                array_add(*result.indices, cast(u32)segment.y - 1);
            case "f"; // @Incomplete
            case;
                error(handler, "Unexpected '%'.\n", rhs);
                continue;
        }
    }

    // for result.vertices print("vertices: %\n", it);
    // for result.indices print("indices: %\n", it);
    return result;
}

to_Mesh :: (shape : Polyline_Soup2) -> Mesh, bool #must {
    mesh : Mesh;

    if is_empty(shape) {
        return mesh, false;
    }

    mesh.geometry_format = .LINES;

    index_offset := 0;
    for polyline : shape.polylines {
        if is_empty(polyline) {
            continue;
        }

        point := polyline.points[0];
        array_add(*mesh.vertices, make_vector3(point.x, point.y, 0));

        for segment_index : 0..polyline.points.count-2 {
            point = polyline.points[segment_index + 1];
            array_add(*mesh.vertices, make_vector3(point.x, point.y, 0));
            array_add(*mesh.indices, xx (index_offset + segment_index));
            array_add(*mesh.indices, xx (index_offset + segment_index  + 1));
        }

        index_offset += polyline.points.count;
    }

    return mesh, true;
}

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

to_Mesh :: (shape : Polygon_Soup2) -> Mesh, bool #must {
    result : Mesh;

    result.geometry_format = .TRIANGLES;

    convex : Polygon_Soup2 = BoostPolygon.convex_decomposition(*shape);

    mesh_index := 0;
    for convex.polygons {
        assert(it.inner_rings.count == 0); // @TODO return false and cleanup
        for i : 0..2 {
            point := it.outer_ring.points[i];
            array_add(*result.vertices, make_vector3(point.x, point.y, 0));
            array_add(*result.indices, xx mesh_index);
            mesh_index += 1;
        }
        if it.outer_ring.points.count == 5 {
            //assert(it.outer_ring.points.count == 5); // @TODO return false and cleanup
            for i : 2..4 {
                point := it.outer_ring.points[i];
                array_add(*result.vertices, make_vector3(point.x, point.y, 0));
                array_add(*result.indices, xx mesh_index);
                mesh_index += 1;
            }
        }
    }

    return result, true;
}

// @TODO only really needed to load polygon objs, but we should just do that with wkt files instead
to_Polygon_Soup2 :: (mesh : Mesh) -> Polygon_Soup2, bool #must {
    result : Polygon_Soup2;
    // make each triangle into a polygon
    // boolean union triangles? (this should be a parameter)
    // not very nice at all but I guess it works
    return result, false;
}

#scope_file

#import "Text_File_Handler";
#import "Basic";
#import "String";
#import "Math";

#import "geometry";