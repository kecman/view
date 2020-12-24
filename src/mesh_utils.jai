#load "shapes.jai";
#import "geometry";

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

make_axes_triad :: (axis_length : float) -> Axes_Triad
{
    par_shapes_triad := make_triad(axis_length);
    defer deinit(*par_shapes_triad);

    using result : Axes_Triad;

    x_axis = to_Mesh(par_shapes_triad.x_axis);
    y_axis = to_Mesh(par_shapes_triad.y_axis);
    z_axis = to_Mesh(par_shapes_triad.z_axis);
    origin = to_Mesh(par_shapes_triad.origin);

    x_axis.color = Vector4.{1, 0, 0, 1};
    y_axis.color = Vector4.{0, 1, 0, 1};
    z_axis.color = Vector4.{0, 0, 1, 1};
    origin.color = Vector4.{1, 1, 1, 1};

    buffer_mesh(*x_axis);
    buffer_mesh(*y_axis);
    buffer_mesh(*z_axis);
    buffer_mesh(*origin);

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