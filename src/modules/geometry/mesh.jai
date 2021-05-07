Geometry_Format :: enum {
    UNKNOWN;
    POINTS;
    LINES;
    TRIANGLES;
}

// Maybe this should be polymorphic on the vertex type?
Mesh :: struct {
    geometry_format := Geometry_Format.UNKNOWN;

    // @Cleanup Store vertices/normals as a flat array to better support 2D polylines? Maybe 'subclass' mesh with using

    // allocator :      Allocator;
    // allocator_data : *void;

    positions : [..]Vector3;
    normals :  [..]Vector3;
    indices :  [..]u32;
    // texture_uvs : [..]Vector2; @Incomplete

    world_from_model : Matrix4 = .{_11 = 1, _22 = 1, _33 = 1, _44 = 1};
}

compute_vertex_normals_from_triangles :: (using mesh : *Mesh) -> bool, string
{
    if mesh.geometry_format != .TRIANGLES {
        return false, "Invalid geometry format";
    }

    if mesh.indices.count % 3 == 0 {
        array_resize(*mesh.normals, mesh.positions.count, initialize=false);
        for i : 0..mesh.indices.count/3-1 {

            i0 := mesh.indices[3 * i + 0];
            i1 := mesh.indices[3 * i + 1];
            i2 := mesh.indices[3 * i + 2];

            if i0 < mesh.positions.count && i0 < mesh.positions.count && i0 < mesh.positions.count {
                e01 := mesh.positions[i0] - mesh.positions[i1];
                e02 := mesh.positions[i0] - mesh.positions[i2];
                n   := normalize(cross(e01, e02));

                mesh.normals[i0] = n;
                mesh.normals[i1] = n;
                mesh.normals[i2] = n;
            } else {
                array_reset(*mesh.normals); // Clear and free memory
                return false, "Out-of-range indices in mesh connectivity array";
            }
        }
        assert(mesh.normals.count == mesh.positions.count);
    }

    return true, "";
}

deinit :: (using mesh : *Mesh) {
    // Note: array_reset frees memory and zeros members
    array_reset(*positions);
    array_reset(*normals);
    array_reset(*indices);

    geometry_format = .UNKNOWN;
}

print_Mesh :: (using mesh : Mesh) {
    print("print_Mesh %\n", mesh);
    for positions print("- vtx[%] %\n", it_index, it);
    for indices  print("- idx[%] %\n", it_index, it);
}

bounding_box :: (using mesh : Mesh) -> AxisBox3 #must {
    box : AxisBox3;
    for * mesh.positions {
        expand(*box, <<it);
    }
    return box;
}

bounding_box :: (using mesh : Mesh, transform : Matrix4) -> AxisBox3 #must {
    box : AxisBox3;
    for point_model : mesh.positions {
        point_transformed := (transform * make_vector4(point_model, 1)).xyz;
        expand(*box, point_transformed);
    }
    return box;
}

transform :: (using mesh : *Mesh, transform : Matrix4) {
    for * mesh.positions {
        <<it = (transform * make_vector4(<<it, 1.)).xyz;
    }

    if mesh.normals.count {
        inverse_transpose := transpose(inverse(transform));
        for * mesh.normals {
            <<it = (inverse_transpose * make_vector4(<<it, 0.)).xyz;
        }
    }
}