#load "shapes.jai";

Triad :: struct {
    x_axis : par_shapes_mesh;
    y_axis : par_shapes_mesh;
    z_axis : par_shapes_mesh;
    origin : par_shapes_mesh;
}

make_triad :: (axis_length : float) -> Triad {
    params := make_triad_parameters(axis_length);
    using params;

    result : Triad;
    using result;

    x_axis = make_axis_arrow(axis_length);
    par_shapes_rotate(x_axis, PI/2, Vector3.{0, 1, 0});

    y_axis = make_axis_arrow(axis_length);
    par_shapes_rotate(y_axis, -PI/2, Vector3.{1, 0, 0});

    z_axis = make_axis_arrow(axis_length);

    origin = par_shapes_create_parametric_sphere(32, 32);
    par_shapes_scale(origin, origin_radius, origin_radius, origin_radius);

    return result;
}

#if 0 #run {
    triad := make_triad(1);
    using triad;

    par_shapes_export(x_axis, "debug_x_arrow.obj");
    par_shapes_export(y_axis, "debug_y_arrow.obj");
    par_shapes_export(z_axis, "debug_z_arrow.obj");
    par_shapes_export(origin, "debug_origin.obj");

    #if 0 {
        cylinder := par_shapes_create_cylinder(8, 5);
        par_shapes_export(cylinder, "debug_cylinder.obj");
        par_shapes_free_mesh(cylinder);

        cone := par_shapes_create_cone(8, 5);
        par_shapes_export(cone, "debug_cone.obj");
        par_shapes_free_mesh(cone);

        disk := par_shapes_create_disk(8, 5);
        par_shapes_export(disk, "debug_disk.obj");
        par_shapes_free_mesh(disk);

        plane := par_shapes_create_plane(8, 5);
        par_shapes_export(plane, "debug_plane.obj");
        par_shapes_free_mesh(plane);

        sphere := par_shapes_create_parametric_sphere(8, 5);
        par_shapes_export(sphere, "debug_sphere.obj");
        par_shapes_free_mesh(sphere);

        hemisphere := par_shapes_create_hemisphere(8, 5);
        par_shapes_export(hemisphere, "debug_hemisphere.obj");
        par_shapes_free_mesh(hemisphere);

        torus := par_shapes_create_torus(16, 16, .2);
        par_shapes_export(torus, "debug_torus.obj");
        par_shapes_free_mesh(torus);
    }

    print("Done writing debug_*.obj meshes\n");
}

#scope_file

Triad_Parameters :: struct {
    axis_radius : float;
    cone_length : float;
    cone_radius : float;
    origin_radius : float;
}

make_triad_parameters :: (axis_length : float) -> Triad_Parameters {
    result : Triad_Parameters;
    result.axis_radius = axis_length / 100;
    result.cone_length = result.axis_radius * 10;
    result.cone_radius = result.axis_radius * 3;
    result.origin_radius = result.axis_radius * 2;
    return result;
}

make_axis_arrow :: (axis_length : float) -> par_shapes_mesh {
    params := make_triad_parameters(axis_length);
    using params;

    result := par_shapes_create_cylinder(32, 1);
    par_shapes_scale(result, axis_radius, axis_radius, axis_length);

    cone := par_shapes_create_cone(32, 1);
    defer par_shapes_free_mesh(cone);
    par_shapes_scale(cone, cone_radius, cone_radius, cone_length);
    par_shapes_translate(cone, make_vector3(0, 0, axis_length));


    base := par_shapes_create_disk(32, 1);
    defer par_shapes_free_mesh(base);
    par_shapes_scale(base, cone_radius, cone_radius, cone_length);
    par_shapes_translate(base, make_vector3(0, 0, axis_length));

    par_shapes_merge(result, cone);
    par_shapes_merge(result, base);

    return result;
}
