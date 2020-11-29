Geometry_Format :: enum {
    UNKNOWN;
    POINTS;
    LINES;
    TRIANGLES;
}

// Maybe this should be polymorphic on the vertex type?
Mesh :: struct {
    geometry_format := Geometry_Format.UNKNOWN;

    vbo : GLuint;
    ibo : GLuint;

    is_buffered := false;
    fully_pathed_filename : string;
    visible : bool = true;
    wireframe : bool = false;
    color : Vector4;

    // @Cleanup Store array slices and put the allocator on the Mesh
    vertices :  [..]Vector3;
    normals :  [..]Vector3;
    indices : [..]u32;
}

buffer_mesh :: (mesh : *Mesh) {
    if !mesh.is_buffered {
        if !mesh.vbo glGenBuffers(1, *mesh.vbo);
        glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo);
        glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * mesh.vertices.count, mesh.vertices.data, GL_STATIC_DRAW);

        if !mesh.ibo glGenBuffers(1, *mesh.ibo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * mesh.indices.count, mesh.indices.data, GL_STATIC_DRAW);

        // @FIXME: Send normals!

        mesh.is_buffered = true;
    }
}

deinit_mesh :: (mesh : *Mesh) {
    if mesh.is_buffered {
        if !mesh.vbo glDeleteBuffers(1, *mesh.vbo);
        mesh.vbo = 0;

        if !mesh.ibo glDeleteBuffers(1, *mesh.ibo);
        mesh.ibo = 0;

        mesh.is_buffered = false;
    }

    // Attention: array_reset frees memory and zeros members
    array_reset(*mesh.vertices);
    array_reset(*mesh.normals);
    array_reset(*mesh.indices);

    mesh.geometry_format = .UNKNOWN;
}

print_Mesh :: (mesh : Mesh) {
    print("print_Mesh %\n", mesh);
    for mesh.vertices print("- vtx[%] %\n", it_index, it);
    for mesh.indices  print("- idx[%] %\n", it_index, it);
}

bounding_box :: (using mesh : Mesh) -> AxisBox2 #must {
    // :OnlyRenderMeshType: @Cleanup implement this properly
    for mesh.vertices if it.z != mesh.vertices[0].z assert(false);

    box : AxisBox2;
    init(*box);
    for * mesh.vertices {
        expand(*box, it.xy);
    }
    return box;
}

