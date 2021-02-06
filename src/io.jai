// Collect the verts, lines, faces etc, and decide what the type of the thing was at the end
// ex1. All verts, l with xy only and no z, or const z => polyline|polylinesoup
// Probably polyline2 should have a z height too


// @Incomplete use the temp allocator for all intermediate allocation? see the memory management how_to
load_obj :: (filename : string) -> Mesh {

    // http://paulbourke.net/dataformats/obj/

    result : Mesh;
    result.fully_pathed_filename = filename;

    result.wireframe = true;

    hash := get_hash(filename);
    result.color.x = cast(float)(hash % 257) / 256;
    result.color.y = cast(float)(get_hash(hash) % 257) / 256;
    result.color.z = cast(float)(get_hash(get_hash(hash)) % 257) / 256;

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
                normal, dim := parse_upto_3d(*handler, rhs);
                if dim != 3 {
                    error(handler, tprint("Expected 3d normal, got dim=%.\n", dim));
                    continue;
                }
                array_add(*result.normals, normal);
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
                triangle := parse_triangle(*handler, rhs);

                if result.geometry_format == .UNKNOWN {
                    result.geometry_format = .TRIANGLES;
                } else if result.geometry_format != .TRIANGLES {
                    error(handler, "Expected consistent geometry format, got %, wanted %.\n", Geometry_Format.TRIANGLES, result.geometry_format);
                    continue;
                }

                // obj indices are 1-based
                // TODO assert no overflow
                array_add(*result.indices, cast(u32)triangle.indices[0] - 1);
                array_add(*result.indices, cast(u32)triangle.indices[1] - 1);
                array_add(*result.indices, cast(u32)triangle.indices[2] - 1);
            case;
                error(handler, "Unexpected '%'.\n", rhs);
                continue;
        }
    }

    buffer_mesh(*result);

    // for result.vertices print("vertices: %\n", it);
    // for result.indices print("indices: %\n", it);

    return result;
}

save_obj :: (filename : string, mesh : Mesh) -> bool
{
    // @Cleanup Are we calling file_close in the right places?

    objfile, success :=  file_open(filename, for_writing=true, keep_existing_content=false);
    if !success {
        return false;
    }

    if mesh.geometry_format == .TRIANGLES {
        if mesh.normals.count {
            for i : 0..mesh.vertices.count-1 {
                px, py, pz := mesh.vertices[i].x, mesh.vertices[i].y, mesh.vertices[i].z;
                nx, ny, nz := mesh.normals[i].x, mesh.normals[i].y, mesh.normals[i].z;
                file_write(*objfile, tprint("v % % %\n", px, py, pz));
                file_write(*objfile, tprint("vn % % %\n", nx, ny, nz));
            }
            for i : 0..(mesh.indices.count/3)-1 {
                a := 1 + mesh.indices[3 * i + 0];
                b := 1 + mesh.indices[3 * i + 1];
                c := 1 + mesh.indices[3 * i + 2];
                file_write(*objfile, tprint("f %//% %//% %//%\n", a, a, b, b, c, c));
            }
        } else {
            for i : 0..mesh.vertices.count-1 {
                file_write(*objfile, tprint("v % % %\n", mesh.vertices[i].x, mesh.vertices[i].y, mesh.vertices[i].z));
            }
            for i : 0..(mesh.indices.count/3)-1 {
                a := 1 + mesh.indices[3 * i + 0];
                b := 1 + mesh.indices[3 * i + 1];
                c := 1 + mesh.indices[3 * i + 2];
                file_write(*objfile, tprint("f % % %\n", a, b, c));
            }
        }
    } else {
        print("@Incomplete save_obj only supports TRIANGLE geometry format, got %\n", mesh.geometry_format);
        return false;
    }

    file_close(*objfile);
    return true;
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

    buffer_mesh(*mesh);

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

    convex : Polygon_Soup2 = BoostPolygon.convex_decomposition(*shape);

    for convex.polygons {
        if it.inner_rings.count != 0 {
            return result, false;
        }
    }

    result.geometry_format = .TRIANGLES;

    mesh_index := 0;
    for convex.polygons {
        i := 0;
        j := 1;
        k := 2;
        while k < it.outer_ring.points.count {
            pi := it.outer_ring.points[i];
            pj := it.outer_ring.points[j];
            pk := it.outer_ring.points[k];
            array_add(*result.vertices, make_vector3(pi.x, pi.y, 0));
            array_add(*result.vertices, make_vector3(pj.x, pj.y, 0));
            array_add(*result.vertices, make_vector3(pk.x, pk.y, 0));
            array_add(*result.indices, xx (mesh_index + 0));
            array_add(*result.indices, xx (mesh_index + 1));
            array_add(*result.indices, xx (mesh_index + 2));
            j += 1;
            k += 1;
            mesh_index += 3;
        }
    }

    buffer_mesh(*result);

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
                // handler.failed = true; // @Incomplete set the failed flag in error cases
                return vector, -1;
            }
            return vector, 3;
        }
        return vector, 2;
    }
    return vector, 1;
}

Triangle :: struct {
    indices : [3]int = .[-1, -1, -1];
    texture : [3]int = .[-1, -1, -1];
    normal :  [3]int = .[-1, -1, -1];
}

parse_triangle :: (handler : *Text_File_Handler, str : string) -> Triangle {
    t : Triangle;

    if count(str, "/") == 0 {
        ok := scan2(str, "% % %", *t.indices[0], *t.indices[1], *t.indices[2]);
        if !ok error(<< handler, "Invalid 'f' line\n");

        return t;
    }

    if count(str, "//") == 3 {
        ok := scan2(str, "%//% %//% %//%", *t.indices[0], *t.normal[0],
                                           *t.indices[1], *t.normal[1],
                                           *t.indices[2], *t.normal[2]);
        if !ok error(<< handler, "Invalid 'f' line\n");

        for 0..2 {
            if t.normal[it] != t.indices[it] {
                msg := tprint("Expected identical normal and vertex indices, got % != %\n", t.normal[it], t.indices[it]);
                error(<< handler, msg);
            }
        }

        return t;
    }

    ok := scan2(str, "%/%/% %/%/% %/%/%", *t.indices[0], *t.texture[0], *t.normal[0],
                                          *t.indices[1], *t.texture[1], *t.normal[1],
                                          *t.indices[2], *t.texture[2], *t.normal[2]);
    if !ok error(<< handler, "Invalid 'f' line\n");

    for 0..2 {
        if t.normal[it] != t.indices[it] {
            msg := tprint("Expected identical normal and vertex indices, got % != %\n", t.normal[it], t.indices[it]);
            error(<< handler, msg);
        }
    }

    return t;
}

#import "Text_File_Handler";
#import "Basic";
#import "File";
#import "String";
#import "Math";
#import "Hash";

#import "geometry";
#import "BoostPolygon"; // for convex_decomposition