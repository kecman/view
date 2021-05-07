
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
        array_add(*mesh.positions, make_vector3(point.x, point.y, 0));

        for edge_index : 0..polyline.points.count-2 {
            point = polyline.points[edge_index + 1];
            array_add(*mesh.positions, make_vector3(point.x, point.y, 0));
            array_add(*mesh.indices, xx (index_offset + edge_index));
            array_add(*mesh.indices, xx (index_offset + edge_index  + 1));
        }

        index_offset += polyline.points.count;
    }

    return mesh, true;
}

to_Polyline_Soup2 :: #bake_arguments to_Polyline_Soup(Point = Vector2);
to_Polyline_Soup3 :: #bake_arguments to_Polyline_Soup(Point = Vector3);

to_Polyline_Soup :: (mesh : Mesh, Point : $Type) -> Polyline_Soup(Point), bool #must {
    result : Polyline_Soup(Point);

    if mesh.geometry_format != .LINES || mesh.indices.count < 2 || mesh.positions.count == 0 {
        return result, false;
    }

    get_edge :: (mesh : Mesh, edge_index : int) -> Indexed_Edge3 {
        assert(2 * edge_index + 1 < mesh.indices.count);

        edge : Indexed_Edge3;
        edge.from_index = mesh.indices[2 * edge_index];
        edge.to_index   = mesh.indices[2 * edge_index + 1];
        edge.from_point = *mesh.positions[edge.from_index];
        edge.to_point   = *mesh.positions[edge.to_index];

        return edge;
    }

    get_point :: inline (point : Vector3) -> Point {
        #if Point == Vector2 {
            return point.xy;
        } else {
            return point;
        }
    }

    edge_count := mesh.indices.count / 2;

    edge_index := 0;
    edge := get_edge(mesh, edge_index);

    // Start a new polyline
    polyline := array_add(*result.polylines);
    array_add(*polyline.points, get_point(<<edge.from_point));

    while true {
        prev_edge := edge;

        // Get next edge
        edge_index += 1;
        if edge_index >= edge_count {
            break;
        }

        edge = get_edge(mesh, edge_index);

        if edge.from_index == prev_edge.to_index {
            // Add to current polyline
            array_add(*polyline.points, get_point(<<edge.from_point));
        } else if edge_index != edge_count {
            // End current polyline
            array_add(*polyline.points, get_point(<<prev_edge.to_point));

            // Start a new polyline
            polyline = array_add(*result.polylines);
            array_add(*polyline.points, get_point(<<edge.from_point));
        }
    }

    // Terminate current polyline
    array_add(*polyline.points, get_point(<<edge.to_point));

    return result, true;
}

to_Mesh :: (shape : Polygon_Soup) -> Mesh, bool #must {
    result : Mesh;

    if shape.polygons.count == 0 {
        return result, false;
    }

#if ENABLE_BOOST_POLYGON {
    #import "BoostPolygon"; // for convex_decomposition
    convex : Polygon_Soup = BoostPolygon.convex_decomposition(*shape);

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
            array_add(*result.positions, make_vector3(pi.x, pi.y, 0));
            array_add(*result.positions, make_vector3(pj.x, pj.y, 0));
            array_add(*result.positions, make_vector3(pk.x, pk.y, 0));
            array_add(*result.indices, xx (mesh_index + 0));
            array_add(*result.indices, xx (mesh_index + 1));
            array_add(*result.indices, xx (mesh_index + 2));
            j += 1;
            k += 1;
            mesh_index += 3;
        }
    }

    return result, true;
} else {
    return result, false;
}
}

// @TODO only really needed to load polygon objs, but we should just do that with wkt files instead
to_Polygon_Soup :: (mesh : Mesh) -> Polygon_Soup, bool #must {
    result : Polygon_Soup;
    // make each triangle into a polygon
    // boolean union triangles? (this should be a parameter)
    // not very nice at all but I guess it works
    return result, false;
}

to_Mesh :: (m : par_shapes_mesh) -> Mesh
{
    using result : Mesh;

    geometry_format = .TRIANGLES;
    array_copy(*positions, m.points);
    array_copy(*normals, m.normals);

    array_reserve(*indices, m.triangles.count * 3);
    memcpy(indices.data, m.triangles.data, m.triangles.count * size_of(m.Triangle));
    indices.count = m.triangles.count * 3;

    // @Incomplete tcoords

    return result;
}

Axes_Triad :: struct {
    x_axis : Mesh_Entity;
    y_axis : Mesh_Entity;
    z_axis : Mesh_Entity;
    origin : Mesh_Entity;
    visible := true;
}

make_axes_triad :: (axis_length : float) -> Axes_Triad
{
    par_shapes_triad := make_triad(axis_length);
    defer deinit(*par_shapes_triad);

    using result : Axes_Triad;

    x_axis.mesh = to_Mesh(par_shapes_triad.x_axis);
    y_axis.mesh = to_Mesh(par_shapes_triad.y_axis);
    z_axis.mesh = to_Mesh(par_shapes_triad.z_axis);
    origin.mesh = to_Mesh(par_shapes_triad.origin);

    x_axis.display_info = .{visible=true, color=.{1, 0, 0, 1}, display_mode=.BLINN_PHONG};
    y_axis.display_info = .{visible=true, color=.{0, 1, 0, 1}, display_mode=.BLINN_PHONG};
    z_axis.display_info = .{visible=true, color=.{0, 0, 1, 1}, display_mode=.BLINN_PHONG};
    origin.display_info = .{visible=true, color=.{1, 1, 1, 1}, display_mode=.BLINN_PHONG};

    buffer_mesh(*x_axis.mesh, *x_axis.display_info);
    buffer_mesh(*y_axis.mesh, *y_axis.display_info);
    buffer_mesh(*z_axis.mesh, *z_axis.display_info);
    buffer_mesh(*origin.mesh, *origin.display_info);

    return result;
}

#if 0 #run {
    using triad := make_triad(1);

    par_shapes_export(x_axis, "debug_x_arrow.obj");
    par_shapes_export(y_axis, "debug_y_arrow.obj");
    par_shapes_export(z_axis, "debug_z_arrow.obj");
    par_shapes_export(origin, "debug_origin.obj");

    #if 0 {
        cylinder := par_shapes_create_cylinder(8, 5);
        par_shapes_export(cylinder, "debug_cylinder.obj");
        deinit(cylinder);

        cone := par_shapes_create_cone(8, 5);
        par_shapes_export(cone, "debug_cone.obj");
        deinit(cone);

        disk := par_shapes_create_disk(8, 5);
        par_shapes_export(disk, "debug_disk.obj");
        deinit(disk);

        plane := par_shapes_create_plane(8, 5);
        par_shapes_export(plane, "debug_plane.obj");
        deinit(plane);

        sphere := par_shapes_create_parametric_sphere(8, 5);
        par_shapes_export(sphere, "debug_sphere.obj");
        deinit(sphere);

        hemisphere := par_shapes_create_hemisphere(8, 5);
        par_shapes_export(hemisphere, "debug_hemisphere.obj");
        deinit(hemisphere);

        torus := par_shapes_create_torus(16, 16, .2);
        par_shapes_export(torus, "debug_torus.obj");
        deinit(torus);
    }

    print("Done writing debug_*.obj meshes\n");
}

make_axis_arrow :: (axis_length : float) -> par_shapes_mesh {
    using params := make_triad_parameters(axis_length);

    result := par_shapes_create_cylinder(32, 1);
    par_shapes_scale(result, axis_radius, axis_radius, axis_length);

    cone := par_shapes_create_cone(32, 1);
    defer deinit(cone);
    par_shapes_scale(cone, cone_radius, cone_radius, cone_length);
    par_shapes_translate(cone, make_vector3(0, 0, axis_length));


    base := par_shapes_create_disk(32, 1);
    defer deinit(base);
    par_shapes_scale(base, cone_radius, cone_radius, cone_length);
    par_shapes_translate(base, make_vector3(0, 0, axis_length));

    par_shapes_merge(result, cone);
    par_shapes_merge(result, base);

    return result;
}

#scope_file

Triad_Parameters :: struct {
    axis_radius : float;
    cone_length : float;
    cone_radius : float;
    origin_radius : float;
}

make_triad_parameters :: (axis_length : float) -> Triad_Parameters {
    using result : Triad_Parameters;

    axis_radius = axis_length / 40;
    cone_length = axis_radius * 10;
    cone_radius = axis_radius * 3;
    origin_radius = axis_radius * 2;

    return result;
}

Triad :: struct {
    x_axis : par_shapes_mesh;
    y_axis : par_shapes_mesh;
    z_axis : par_shapes_mesh;
    origin : par_shapes_mesh;
}

make_triad :: (axis_length : float) -> Triad {
    using params := make_triad_parameters(axis_length);

    using result : Triad;

    x_axis = make_axis_arrow(axis_length);
    par_shapes_rotate(x_axis, PI/2, Vector3.{0, 1, 0});

    y_axis = make_axis_arrow(axis_length);
    par_shapes_rotate(y_axis, -PI/2, Vector3.{1, 0, 0});

    z_axis = make_axis_arrow(axis_length);

    origin = par_shapes_create_parametric_sphere(32, 32);
    par_shapes_scale(origin, origin_radius, origin_radius, origin_radius);

    return result;
}

deinit :: (using triad : *Triad) {
    deinit(triad.x_axis);
    deinit(triad.y_axis);
    deinit(triad.z_axis);
    deinit(triad.origin);
}
