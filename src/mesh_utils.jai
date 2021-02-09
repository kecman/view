
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

to_Polyline_Soup2 :: (mesh : Mesh, $Point : Type = Vector2) -> Polyline_Soup(Point), bool #must {
    result : Polyline_Soup(Point);

    if mesh.geometry_format != .LINES || mesh.indices.count < 2 || mesh.vertices.count == 0 {
        return result, false;
    }

    // @Cleanup Implement a segment iterator?

    Segment :: struct {
        from_index : int = ---;
        to_index : int = ---;
        from_point : Point = ---;
        to_point : Point = ---;
    }

    get_segment :: (mesh : Mesh, segment_index : int) -> Segment {
        assert(2 * segment_index + 1 < mesh.indices.count);

        segment : Segment;
        segment.from_index = mesh.indices[2 * segment_index];
        segment.to_index   = mesh.indices[2 * segment_index + 1];
        #if Point == Vector2 {
        segment.from_point = mesh.vertices[segment.from_index].xy;
        segment.to_point   = mesh.vertices[segment.to_index].xy;
        } else {
        segment.from_point = mesh.vertices[segment.from_index];
        segment.to_point   = mesh.vertices[segment.to_index];
        }
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
    array_copy(*vertices, m.points);
    array_copy(*normals, m.normals);

    array_reserve(*indices, m.triangles.count * 3);
    memcpy(indices.data, m.triangles.data, m.triangles.count * size_of(m.Triangle));
    indices.count = m.triangles.count * 3;

    // @Incomplete tcoords

    return result;
}

Axes_Triad :: struct {
    x_axis : Mesh;
    y_axis : Mesh;
    z_axis : Mesh;
    origin : Mesh;
}

set_visibility :: (using triad : *Axes_Triad, visibility : bool)
{
    x_axis.visible = visibility;
    y_axis.visible = visibility;
    z_axis.visible = visibility;
    origin.visible = visibility;
}

make_axes_triad :: (axis_length : float) -> Axes_Triad
{
    par_shapes_triad := make_triad(axis_length);
    defer deinit(*par_shapes_triad);

    using result : Axes_Triad;

    x_axis = to_Mesh(par_shapes_triad.x_axis);
    y_axis = to_Mesh(par_shapes_triad.y_axis);
    z_axis = to_Mesh(par_shapes_triad.z_axis);
    origin = to_Mesh(par_shapes_triad.origin);

    buffer_mesh(*x_axis);
    buffer_mesh(*y_axis);
    buffer_mesh(*z_axis);
    buffer_mesh(*origin);

    x_axis.color = Vector4.{1, 0, 0, 1};
    y_axis.color = Vector4.{0, 1, 0, 1};
    z_axis.color = Vector4.{0, 0, 1, 1};
    origin.color = Vector4.{1, 1, 1, 1};

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

#scope_file

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

Triad_Parameters :: struct {
    axis_radius : float;
    cone_length : float;
    cone_radius : float;
    origin_radius : float;
}

make_triad_parameters :: (axis_length : float) -> Triad_Parameters {
    using result : Triad_Parameters;

    axis_radius = axis_length / 100;
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

#scope_file

#load "shapes.jai";
#import "geometry";
