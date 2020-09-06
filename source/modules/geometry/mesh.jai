Geometry_Format :: enum {
    UNKNOWN;
    POINTS;
    LINES;
    TRIANGLES;
}

Mesh :: struct {
    geometry_format := Geometry_Format.UNKNOWN;

    vbo : GLuint;
    ibo : GLuint;

    is_dirty := true;
    fully_pathed_filename : string;
    visible : bool = true;

    // @Cleanup Store array slices and put the allocator on the Mesh
    vertices :  [..]Vector3;
    indices : [..]int;
}

buffer_mesh :: (mesh : Mesh) {
    if is_dirty {
        if !vbo glGenBuffers(1, *vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * mesh.vertices.count, mesh.vertices.data, GL_STATIC_DRAW);

        if !ibo glGenBuffers(1, *ibo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(int) * mesh.indices.count, mesh.indices.data, GL_STATIC_DRAW);

        is_dirty = false;
    }
}

bounding_box :: (using mesh : Mesh) -> AxisBox2 #must {
    // :OnlyRenderMeshType: @Cleanup implement this properly
    for mesh.vertices if it.z != mesh.vertices[0].z assert(false);

    box : AxisBox2;
    init(*box);
    for * polylines {
        polyline_box := bounding_box(it);
        expand(*box, *polyline_box);
    }
    return box;
}

