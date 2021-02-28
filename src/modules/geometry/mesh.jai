Geometry_Format :: enum {
    UNKNOWN;
    POINTS;
    LINES;
    TRIANGLES;
}

// Maybe this should be polymorphic on the vertex type?
Mesh :: struct {
    geometry_format := Geometry_Format.UNKNOWN;

#if USE_GRAPHICS {
    vbo : GLuint;
    ibo : GLuint;
}

    is_dirty := true;
    fully_pathed_filename : string;
    visible : bool = true;
    wireframe : bool = false;
    color : Vector4;

    // @Cleanup Store vertices/normals as a flat array to better support 2D polylines? Maybe 'subclass' mesh with using

    // allocator :      Allocator;
    // allocator_data : *void;

    positions : [..]Vector3;
    normals :  [..]Vector3;
    indices :  [..]u32;
    // @Incomplete tcoords?

    world_from_model : Matrix4 = .{_11 = 1, _22 = 1, _33 = 1, _44 = 1};
}

buffer_mesh :: (using mesh : *Mesh) {
#if USE_GRAPHICS {
    if is_dirty {
        if !vbo glGenBuffers(1, *vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, size_of(Vector3) * positions.count, positions.data, GL_STATIC_DRAW);

        if !ibo glGenBuffers(1, *ibo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * indices.count, indices.data, GL_STATIC_DRAW);

        // @FIXME: Send normals!

        is_dirty = false;
    }
}
}

deinit :: (using mesh : *Mesh) {
#if USE_GRAPHICS {
    if vbo glDeleteBuffers(1, *vbo);
    if ibo glDeleteBuffers(1, *ibo);

    vbo = 0;
    ibo = 0;
}
    is_dirty = true;

    // Note: array_reset frees memory and zeros members
    array_reset(*positions);
    array_reset(*normals);
    array_reset(*indices);

    geometry_format = .UNKNOWN;
    free(fully_pathed_filename.data);
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

// Or maybe we should have a Renderable_Mesh? bleh..
#if USE_GRAPHICS {
#import "GL"; // for GLuint, glGenBuffers, glDeleteBuffers
#run compiler_set_type_info_flags(GL_Procedures, .NO_SIZE_COMPLAINT);
}