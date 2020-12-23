// Based on https://github.com/prideout/par/blob/master/par_shapes.h
// par_shapes is distributed under the MIT license. Copyright (c) 2019 Philip Rideout

#import "Basic";

#if 1 {
test :: ()
{
    cylinder := par_shapes_create_cylinder(8, 5);
    par_shapes_export(cylinder, "debug_cylinder.obj");
    par_shapes_free_mesh(cylinder);

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

    triad := make_triad(1);
    using triad;

    par_shapes_export(x_axis, "debug_x_arrow.obj");
    par_shapes_export(y_axis, "debug_y_arrow.obj");
    par_shapes_export(z_axis, "debug_z_arrow.obj");
    par_shapes_export(origin, "debug_origin.obj");

    #if 0 {
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
    }

    print("Done writing debug_*.obj meshes\n");
}

// main :: () { test(); }
#run test();
}

// TODO use array views and a single allocator
par_shapes_mesh :: struct
{
    points : [..]Vector3;
    triangles : [..][3]u32;
    normals : [..]Vector3;
    tcoords : [..]Vector2;
};

par_shapes_free_mesh :: (mesh : par_shapes_mesh) -> void
{
    array_free(mesh.points);
    array_free(mesh.triangles);
    array_free(mesh.normals);
    array_free(mesh.tcoords);
}

// Generators ------------------------------------------------------------------

// Create a parametric surface from a callback function that consumes a 2D
// point in [0,1] and produces a 3D point.
par_shapes_fn :: #type (uv : Vector2, userdata : *void) -> Vector3;

par_shapes_create_cylinder :: (slices : u32, stacks : u32) -> par_shapes_mesh
{
    if (slices < 3 || stacks < 1) {
        return .{};
    }
    return par_shapes_create_parametric(par_shapes__cylinder, slices, stacks, null);
}

par_shapes_create_cone :: (slices : u32, stacks : u32) -> par_shapes_mesh
{
    if (slices < 3 || stacks < 1) {
        return .{};
    }
    return par_shapes_create_parametric(par_shapes__cone, slices, stacks, null);
}

par_shapes_create_disk :: (slices : u32, stacks : u32) -> par_shapes_mesh
{
    m := par_shapes_create_cone(slices, stacks);
    par_shapes_scale(m, 1, 1, 0);
    return m;
}

par_shapes_create_parametric_sphere :: (slices : u32, stacks : u32) -> par_shapes_mesh
{
    if (slices < 3 || stacks < 3) {
        return .{};
    }
    m := par_shapes_create_parametric(par_shapes__sphere, slices, stacks, null);
    // par_shapes_remove_degenerate(m, par_shapes__epsilon_degenerate_sphere); // @Incomplete
    return m;
}

par_shapes_create_plane :: (slices : u32, stacks : u32) -> par_shapes_mesh
{
    if (slices < 1 || stacks < 1) {
        return .{};
    }
    return par_shapes_create_parametric(par_shapes__plane, slices, stacks, null);
}

/*

par_shapes_mesh* par_shapes_create_hemisphere(int slices, int stacks)
{
    if (slices < 3 || stacks < 3) {
        return 0;
    }
    par_shapes_mesh* m = par_shapes_create_parametric(par_shapes__hemisphere,
        slices, stacks, 0);
    par_shapes_remove_degenerate(m, par_shapes__epsilon_degenerate_sphere);
    return m;
}

par_shapes_mesh* par_shapes_create_torus(int slices, int stacks, float radius)
{
    if (slices < 3 || stacks < 3) {
        return 0;
    }
    assert(radius <= 1.0 && "Use smaller radius to avoid self-intersection.");
    assert(radius >= 0.1 && "Use larger radius to avoid self-intersection.");
    void* userdata = (void*) &radius;
    return par_shapes_create_parametric(par_shapes__torus, slices,
        stacks, userdata);
}

par_shapes_mesh* par_shapes_create_klein_bottle(int slices, int stacks)
{
    if (slices < 3 || stacks < 3) {
        return 0;
    }
    par_shapes_mesh* mesh = par_shapes_create_parametric(
        par_shapes__klein, slices, stacks, 0);
    int face = 0;
    for (int stack = 0; stack < stacks; stack++) {
        for (int slice = 0; slice < slices; slice++, face += 2) {
            if (stack < 27 * stacks / 32) {
                par_shapes_invert(mesh, face, 2);
            }
        }
    }
    par_shapes__compute_welded_normals(mesh);
    return mesh;
}

par_shapes_mesh* par_shapes_create_trefoil_knot(int slices, int stacks,
    float radius)
{
    if (slices < 3 || stacks < 3) {
        return 0;
    }
    assert(radius <= 3.0 && "Use smaller radius to avoid self-intersection.");
    assert(radius >= 0.5 && "Use larger radius to avoid self-intersection.");
    void* userdata = (void*) &radius;
    return par_shapes_create_parametric(par_shapes__trefoil, slices,
        stacks, userdata);
}

*/

par_shapes_create_parametric :: (fn : par_shapes_fn, slices : u32, stacks : u32, userdata : *void) -> par_shapes_mesh
{
    mesh : par_shapes_mesh;

    npoints := (slices + 1) * (stacks + 1);
    ntriangles := 2 * slices * stacks;

    array_resize(*mesh.points,  npoints);
    array_resize(*mesh.tcoords, npoints);
    array_resize(*mesh.triangles, ntriangles);

    // Generate vertices and texture coordinates.
    i := 0;
    for stack : 0..stacks {
        uv : Vector2;
        uv.x = cast(float)stack / cast(float)stacks;
        for slice : 0..slices {
            uv.y = cast(float) slice / cast(float)slices;
            mesh.tcoords[i] = uv;
            mesh.points[i] = fn(uv, userdata);
            i += 1;
        }
    }
    assert(i == npoints);

    // Generate faces.
    v : u32 = 0;
    f := 0;
    for stack : 0..stacks-1 {
        for slice : 0..slices-1 {
            next := slice + 1;

            mesh.triangles[f][0] = v + slice + slices + 1;
            mesh.triangles[f][1] = v + next;
            mesh.triangles[f][2] = v + slice;
            f += 1;

            mesh.triangles[f][0] = v + slice + slices + 1;
            mesh.triangles[f][1] = v + next + slices + 1;
            mesh.triangles[f][2] = v + next;
            f += 1;
        }
        v += slices + 1;
    }
    assert(f == ntriangles);

    // par_shapes__compute_welded_normals(mesh);
    return mesh;
}

// Queries ---------------------------------------------------------------------

par_shapes_export :: (mesh : par_shapes_mesh, filename : string) -> void
{
    objfile, success :=  file_open(filename, for_writing=true, keep_existing_content=false);
    assert(success);

    npoints := mesh.points.count;
    ntriangles := mesh.triangles.count;

    if mesh.tcoords.count && mesh.normals.count {
        for i : 0..npoints-1 {
            file_write(*objfile, tprint("v % % %\n", mesh.points[i].x, mesh.points[i].y, mesh.points[i].z));
            file_write(*objfile, tprint("vt % %\n", mesh.tcoords[i].x, mesh.tcoords[i].y));
            file_write(*objfile, tprint("vn % % %\n", mesh.normals[i].x, mesh.normals[i].y, mesh.normals[i].z));
        }
        for i : 0..ntriangles-1 {
            a := 1 + mesh.triangles[i][0];
            b := 1 + mesh.triangles[i][1];
            c := 1 + mesh.triangles[i][2];
            file_write(*objfile, tprint("f %/%/% %/%/% %/%/%\n", a, a, a, b, b, b, c, c, c));
        }
    } else if mesh.normals.count {
        for i : 0..npoints-1 {
            file_write(*objfile, tprint("v % % %\n", mesh.points[i].x, mesh.points[i].y, mesh.points[i].z));
            file_write(*objfile, tprint("vn % % %\n", mesh.normals[i].x, mesh.normals[i].y, mesh.normals[i].z));
        }
        for i : 0..ntriangles-1 {
            a := 1 + mesh.triangles[i][0];
            b := 1 + mesh.triangles[i][1];
            c := 1 + mesh.triangles[i][2];
            file_write(*objfile, tprint("f %//% %//% %//%\n", a, a, b, b, c, c));
        }
    } else if mesh.tcoords.count {
        for i : 0..npoints-1 {
            file_write(*objfile, tprint("v % % %\n", mesh.points[i].x, mesh.points[i].y, mesh.points[i].z));
            file_write(*objfile, tprint("vt % %\n", mesh.tcoords[i].x, mesh.tcoords[i].y));
        }
        for i : 0..ntriangles-1 {
            a := 1 + mesh.triangles[i][0];
            b := 1 + mesh.triangles[i][1];
            c := 1 + mesh.triangles[i][2];
            file_write(*objfile, tprint("f %/% %/% %/%\n", a, a, b, b, c, c));
        }
    } else {
        for i : 0..npoints-1 {
            file_write(*objfile, tprint("v % % %\n", mesh.points[i].x, mesh.points[i].y, mesh.points[i].z));
        }
        for i : 0..ntriangles-1 {
            a := 1 + mesh.triangles[i][0];
            b := 1 + mesh.triangles[i][1];
            c := 1 + mesh.triangles[i][2];
            file_write(*objfile, tprint("f % % %\n", a, b, c));
        }
    }
    file_close(*objfile);
}

// Transformations -------------------------------------------------------------

par_shapes_translate :: (mesh : par_shapes_mesh, displacement : Vector3)
{
    for * mesh.points {
        <<it += displacement;
    }
}

// @TODO implement this using Math.jai
par_shapes_rotate :: (mesh : par_shapes_mesh, radians : float, axis : Vector3) {
    s := sin(radians);
    c := cos(radians);
    x := axis.x;
    y := axis.y;
    z := axis.z;
    xy := x * y;
    yz := y * z;
    zx := z * x;
    oneMinusC := 1 - c;

    col0 : [3]float = ---;
    col0[0] = (((x * x) * oneMinusC) + c);
    col0[1] = ((xy * oneMinusC) + (z * s));
    col0[2] = ((zx * oneMinusC) - (y * s));

    col1 : [3]float = ---;
    col1[0] = ((xy * oneMinusC) - (z * s));
    col1[1] = (((y * y) * oneMinusC) + c);
    col1[2] = ((yz * oneMinusC) + (x * s));

    col2 : [3]float = ---;
    col2[0] = ((zx * oneMinusC) + (y * s));
    col2[1] = ((yz * oneMinusC) - (x * s));
    col2[2] = (((z * z) * oneMinusC) + c);

    for * point : mesh.points {
        x := col0[0] * point.x + col1[0] * point.y + col2[0] * point.z;
        y := col0[1] * point.x + col1[1] * point.y + col2[1] * point.z;
        z := col0[2] * point.x + col1[2] * point.y + col2[2] * point.z;
        point.x = x;
        point.y = y;
        point.z = z;
    }

    // @TODO @Bug is this rotating normals correctly??? No inverse transpose??
    if mesh.normals.count {
        for * normal : mesh.normals {
            x := col0[0] * normal.x + col1[0] * normal.y + col2[0] * normal.z;
            y := col0[1] * normal.x + col1[1] * normal.y + col2[1] * normal.z;
            z := col0[2] * normal.x + col1[2] * normal.y + col2[2] * normal.z;
            normal.x = x;
            normal.y = y;
            normal.z = z;
        }
    }
}

par_shapes_scale :: (mesh : par_shapes_mesh, x : float, y : float, z : float)
{
    for * point : mesh.points {
        point.x *= x;
        point.y *= y;
        point.z *= z;
    }

    if mesh.normals.count && !(x == y && x == z) {
        x_zero := (x == 0);
        y_zero := (y == 0);
        z_zero := (z == 0);

        if !x_zero && !y_zero && !z_zero {
            x = 1. / x;
            y = 1. / y;
            z = 1. / z;
        } else {
            x = ifx x_zero && !y_zero && !z_zero then 1. else 0.;
            y = ifx y_zero && !x_zero && !z_zero then 1. else 0.;
            z = ifx z_zero && !x_zero && !y_zero then 1. else 0.;
        }

        for * normal : mesh.normals {
            normal.x *= x;
            normal.y *= y;
            normal.z *= z;
            <<normal = normalize(<<normal);
        }
    }
}

par_shapes_merge :: (dst : par_shapes_mesh, src : par_shapes_mesh)
{
    poffset := dst.points.count;
    toffset := dst.triangles.count;

    npoints := dst.points.count + src.points.count;
    ntriangles := dst.triangles.count + src.triangles.count;

    array_resize(*dst.points, npoints);
    for i : 0..src.points.count-1 {
        dst.points[poffset + i] = src.points[i];
    }

    if src.normals.count || dst.normals.count {
        array_resize(*dst.normals, npoints);
        for i : 0..src.normals.count-1 {
            dst.normals[poffset + i] = src.normals[i];
        }
    }

    if src.tcoords.count || dst.tcoords.count {
        array_resize(*dst.tcoords, npoints);
        for i : 0..src.tcoords.count-1 {
            dst.tcoords[poffset + i] = src.tcoords[i];
        }
    }

    array_resize(*dst.triangles, ntriangles);
    for i : 0..src.triangles.count-1 {
        dst.triangles[toffset + i][0] = xx poffset + src.triangles[i][0];
        dst.triangles[toffset + i][1] = xx poffset + src.triangles[i][1];
        dst.triangles[toffset + i][2] = xx poffset + src.triangles[i][2];
    }
}

// void par_shapes_merge(par_shapes_mesh* dst, par_shapes_mesh const* src);
// void par_shapes_merge_and_free(par_shapes_mesh* dst, par_shapes_mesh* src);


#scope_file

#import "Math";
#import "File";

// @TODO use automatic differentiation here??

par_shapes__cylinder :: (uv : Vector2, userdata : *void) -> Vector3
{
    theta := uv.y * 2 * PI;
    return make_vector3(sin(theta), cos(theta), uv.x);
}

par_shapes__cone :: (uv : Vector2, userdata : *void) -> Vector3
{
    r := 1 - uv.x;
    theta := uv.y * 2 * PI;
    return make_vector3(r * sin(theta), r * cos(theta), uv.x);
}

par_shapes__sphere :: (uv : Vector2, userdata : *void) -> Vector3
{
    phi := uv.x * PI;
    theta := uv.y * 2 * PI;
    return make_vector3(cos(theta) * sin(phi), sin(theta) * sin(phi), cos(phi));
}

par_shapes__plane :: (uv : Vector2, userdata : *void) -> Vector3
{
    return make_vector3(uv.x, uv.y, 0);
}


/*

static void par_shapes__hemisphere(float const* uv, float* xyz, void* userdata)
{
    float phi = uv[0] * PAR_PI;
    float theta = uv[1] * PAR_PI;
    xyz[0] = cosf(theta) * sinf(phi);
    xyz[1] = sinf(theta) * sinf(phi);
    xyz[2] = cosf(phi);
}

static void par_shapes__klein(float const* uv, float* xyz, void* userdata)
{
    float u = uv[0] * PAR_PI;
    float v = uv[1] * 2 * PAR_PI;
    u = u * 2;
    if (u < PAR_PI) {
        xyz[0] = 3 * cosf(u) * (1 + sinf(u)) + (2 * (1 - cosf(u) / 2)) *
            cosf(u) * cosf(v);
        xyz[2] = -8 * sinf(u) - 2 * (1 - cosf(u) / 2) * sinf(u) * cosf(v);
    } else {
        xyz[0] = 3 * cosf(u) * (1 + sinf(u)) + (2 * (1 - cosf(u) / 2)) *
            cosf(v + PAR_PI);
        xyz[2] = -8 * sinf(u);
    }
    xyz[1] = -2 * (1 - cosf(u) / 2) * sinf(v);
}


static void par_shapes__torus(float const* uv, float* xyz, void* userdata)
{
    float major = 1;
    float minor = *((float*) userdata);
    float theta = uv[0] * 2 * PAR_PI;
    float phi = uv[1] * 2 * PAR_PI;
    float beta = major + minor * cosf(phi);
    xyz[0] = cosf(theta) * beta;
    xyz[1] = sinf(theta) * beta;
    xyz[2] = sinf(phi) * minor;
}

static void par_shapes__trefoil(float const* uv, float* xyz, void* userdata)
{
    float minor = *((float*) userdata);
    const float a = 0.5f;
    const float b = 0.3f;
    const float c = 0.5f;
    const float d = minor * 0.1f;
    const float u = (1 - uv[0]) * 4 * PAR_PI;
    const float v = uv[1] * 2 * PAR_PI;
    const float r = a + b * cos(1.5f * u);
    const float x = r * cos(u);
    const float y = r * sin(u);
    const float z = c * sin(1.5f * u);
    float q[3];
    q[0] =
        -1.5f * b * sin(1.5f * u) * cos(u) - (a + b * cos(1.5f * u)) * sin(u);
    q[1] =
        -1.5f * b * sin(1.5f * u) * sin(u) + (a + b * cos(1.5f * u)) * cos(u);
    q[2] = 1.5f * c * cos(1.5f * u);
    par_shapes__normalize3(q);
    float qvn[3] = {q[1], -q[0], 0};
    par_shapes__normalize3(qvn);
    float ww[3];
    par_shapes__cross3(ww, q, qvn);
    xyz[0] = x + d * (qvn[0] * cos(v) + ww[0] * sin(v));
    xyz[1] = y + d * (qvn[1] * cos(v) + ww[1] * sin(v));
    xyz[2] = z + d * ww[2] * sin(v);
}
*/

/*
par_shapes__compute_welded_normals :: (m : par_shapes_mesh) -> void
{
    const float epsilon = par_shapes__epsilon_welded_normals;
    m->normals = PAR_MALLOC(float, m->npoints * 3);
    PAR_SHAPES_T* weldmap = PAR_MALLOC(PAR_SHAPES_T, m->npoints);
    par_shapes_mesh* welded = par_shapes_weld(m, epsilon, weldmap);
    par_shapes_compute_normals(welded);
    float* pdst = m->normals;
    for (int i = 0; i < m->npoints; i++, pdst += 3) {
        int d = weldmap[i];
        float const* pnormal = welded->normals + d * 3;
        pdst[0] = pnormal[0];
        pdst[1] = pnormal[1];
        pdst[2] = pnormal[2];
    }
    PAR_FREE(weldmap);
    par_shapes_free_mesh(welded);
}

void par_shapes_compute_normals(par_shapes_mesh* m)
{
    PAR_FREE(m->normals);
    m->normals = PAR_CALLOC(float, m->npoints * 3);
    PAR_SHAPES_T const* triangle = m->triangles;
    float next[3], prev[3], cp[3];
    for (int f = 0; f < m->ntriangles; f++, triangle += 3) {
        float const* pa = m->points + 3 * triangle[0];
        float const* pb = m->points + 3 * triangle[1];
        float const* pc = m->points + 3 * triangle[2];
        par_shapes__copy3(next, pb);
        par_shapes__subtract3(next, pa);
        par_shapes__copy3(prev, pc);
        par_shapes__subtract3(prev, pa);
        par_shapes__cross3(cp, next, prev);
        par_shapes__add3(m->normals + 3 * triangle[0], cp);
        par_shapes__copy3(next, pc);
        par_shapes__subtract3(next, pb);
        par_shapes__copy3(prev, pa);
        par_shapes__subtract3(prev, pb);
        par_shapes__cross3(cp, next, prev);
        par_shapes__add3(m->normals + 3 * triangle[1], cp);
        par_shapes__copy3(next, pa);
        par_shapes__subtract3(next, pc);
        par_shapes__copy3(prev, pb);
        par_shapes__subtract3(prev, pc);
        par_shapes__cross3(cp, next, prev);
        par_shapes__add3(m->normals + 3 * triangle[2], cp);
    }
    float* normal = m->normals;
    for (int p = 0; p < m->npoints; p++, normal += 3) {
        par_shapes__normalize3(normal);
    }
}

par_shapes_mesh* par_shapes_weld(par_shapes_mesh const* mesh, float epsilon, PAR_SHAPES_T* weldmap)
{
    par_shapes_mesh* clone = par_shapes_clone(mesh, 0);
    float aabb[6];
    int gridsize = 20;
    float maxcell = gridsize - 1;
    par_shapes_compute_aabb(clone, aabb);
    float scale[3] = {
        aabb[3] == aabb[0] ? 1.0f : maxcell / (aabb[3] - aabb[0]),
        aabb[4] == aabb[1] ? 1.0f : maxcell / (aabb[4] - aabb[1]),
        aabb[5] == aabb[2] ? 1.0f : maxcell / (aabb[5] - aabb[2]),
    };
    par_shapes_translate(clone, -aabb[0], -aabb[1], -aabb[2]);
    par_shapes_scale(clone, scale[0], scale[1], scale[2]);
    PAR_SHAPES_T* sortmap = PAR_MALLOC(PAR_SHAPES_T, mesh->npoints);
    par_shapes__sort_points(clone, gridsize, sortmap);
    bool owner = false;
    if (!weldmap) {
        owner = true;
        weldmap = PAR_MALLOC(PAR_SHAPES_T, mesh->npoints);
    }
    for (int i = 0; i < mesh->npoints; i++) {
        weldmap[i] = i;
    }
    par_shapes__weld_points(clone, gridsize, epsilon, weldmap);
    if (owner) {
        PAR_FREE(weldmap);
    } else {
        PAR_SHAPES_T* newmap = PAR_MALLOC(PAR_SHAPES_T, mesh->npoints);
        for (int i = 0; i < mesh->npoints; i++) {
            newmap[i] = weldmap[sortmap[i]];
        }
        memcpy(weldmap, newmap, sizeof(PAR_SHAPES_T) * mesh->npoints);
        PAR_FREE(newmap);
    }
    PAR_FREE(sortmap);
    par_shapes_scale(clone, 1.0 / scale[0], 1.0 / scale[1], 1.0 / scale[2]);
    par_shapes_translate(clone, aabb[0], aabb[1], aabb[2]);
    return clone;
}

void par_shapes_translate(par_shapes_mesh* m, float x, float y, float z)
{
    float* points = m->points;
    for (int i = 0; i < m->npoints; i++) {
        *points++ += x;
        *points++ += y;
        *points++ += z;
    }
}

void par_shapes_scale(par_shapes_mesh* m, float x, float y, float z)
{
    float* points = m->points;
    for (int i = 0; i < m->npoints; i++) {
        *points++ *= x;
        *points++ *= y;
        *points++ *= z;
    }
    float* n = m->normals;
    if (n && (x != y || x != z || y != z)) {
        x = 1.0f / x;
        y = 1.0f / y;
        z = 1.0f / z;
        for (int i = 0; i < m->npoints; i++, n += 3) {
            n[0] *= x;
            n[1] *= y;
            n[2] *= z;
            par_shapes__normalize3(n);
        }
    }
}


void par_shapes_compute_aabb(par_shapes_mesh const* m, float* aabb)
{
    float* points = m->points;
    aabb[0] = aabb[3] = points[0];
    aabb[1] = aabb[4] = points[1];
    aabb[2] = aabb[5] = points[2];
    points += 3;
    for (int i = 1; i < m->npoints; i++, points += 3) {
        aabb[0] = PAR_MIN(points[0], aabb[0]);
        aabb[1] = PAR_MIN(points[1], aabb[1]);
        aabb[2] = PAR_MIN(points[2], aabb[2]);
        aabb[3] = PAR_MAX(points[0], aabb[3]);
        aabb[4] = PAR_MAX(points[1], aabb[4]);
        aabb[5] = PAR_MAX(points[2], aabb[5]);
    }
}

par_shapes_mesh* par_shapes_clone(par_shapes_mesh const* mesh, par_shapes_mesh* clone)
{
    if (!clone) {
        clone = PAR_CALLOC(par_shapes_mesh, 1);
    }
    clone->npoints = mesh->npoints;
    clone->points = PAR_REALLOC(float, clone->points, 3 * clone->npoints);
    memcpy(clone->points, mesh->points, sizeof(float) * 3 * clone->npoints);
    clone->ntriangles = mesh->ntriangles;
    clone->triangles = PAR_REALLOC(PAR_SHAPES_T, clone->triangles, 3 *
        clone->ntriangles);
    memcpy(clone->triangles, mesh->triangles,
        sizeof(PAR_SHAPES_T) * 3 * clone->ntriangles);
    if (mesh->normals) {
        clone->normals = PAR_REALLOC(float, clone->normals, 3 * clone->npoints);
        memcpy(clone->normals, mesh->normals,
            sizeof(float) * 3 * clone->npoints);
    }
    if (mesh->tcoords) {
        clone->tcoords = PAR_REALLOC(float, clone->tcoords, 2 * clone->npoints);
        memcpy(clone->tcoords, mesh->tcoords,
            sizeof(float) * 2 * clone->npoints);
    }
    return clone;
}
*/