VertexLabelStyle :: struct {
    show_position := false;
    show_index := false;

    format_float : FormatFloat;
    format_float.trailing_width = 8;
    format_float.zero_removal = .NO;

    label_scale := .3;
    label_color : Vector4 = .{1., 1., 1., 1.};

    point_size : int = 2; // 0, 2, 4, 6
    line_width : int = 1; // 1, 1, 2, 3
}

Display_Mode :: enum {
    NORMALS :: 0;
    SOLID_COLOR :: 1;
    BLINN_PHONG :: 2;
}

// @Cleanup rename to Render_Info
Display_Info :: struct {
    is_dirty := true;

    vbo : GLuint;
    ibo : GLuint;

    visible := true;
    visible_sweep_hovered := false;
    flash_hovered := false;
    flash_wave_dt : float = 0.;

    wireframe := false;
    color : Vector4;
    display_mode := Display_Mode.BLINN_PHONG;

    bounding_sphere : Sphere; // In world space
    bounding_aabb : AxisBox3; // In world space
}

buffer_mesh :: (mesh : *Mesh, info : *Display_Info) {
    if info.is_dirty {
        if mesh.geometry_format == .TRIANGLES && !mesh.normals.count {
            // log("Computing and assigning triangle normals to vertices\n");
            success, failure_reason := compute_vertex_normals_from_triangles(mesh);
            if !success {
                log("Computing and assigning triangle normals to vertices, reason: \"%\"",
                    failure_reason);
            }
        }

        info.bounding_sphere = bounding_sphere_ritter(mesh.positions);
        info.bounding_aabb = make_axis_box3(..mesh.positions);

        NP := size_of(Vector3) * mesh.positions.count;
        NN := size_of(Vector3) * mesh.normals.count;
        NI := size_of(u32) * mesh.indices.count;

        if !info.vbo glGenBuffers(1, *info.vbo);

        glBindBuffer(GL_ARRAY_BUFFER, info.vbo);
        glBufferData(GL_ARRAY_BUFFER, NP + NN, null, GL_STATIC_DRAW);
        glBufferSubData(GL_ARRAY_BUFFER, 0, NP, mesh.positions.data);
        glBufferSubData(GL_ARRAY_BUFFER, NP, NN, mesh.normals.data);

        if !info.ibo glGenBuffers(1, *info.ibo);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, info.ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, NI, mesh.indices.data, GL_STATIC_DRAW);

        info.is_dirty = false;
    }
}

render_mesh :: (mesh : Mesh, info : Display_Info, style : VertexLabelStyle, flash_dt : float = 0) {
    using app;

    assert(!info.is_dirty);

    glUseProgram(mesh_shader);

    {
        model_loc := glGetUniformLocation(mesh_shader, "world_from_model");
        glUniformMatrix4fv(model_loc, 1, true, *mesh.world_from_model._11);
    }

    {
        view_loc := glGetUniformLocation(mesh_shader, "view_from_world");
        view_from_world := make_look_at_matrix(camera);
        glUniformMatrix4fv(view_loc, 1, true, *view_from_world._11);
    }

    {
        projection_loc := glGetUniformLocation(mesh_shader, "projection_from_view");
        projection_from_view := make_orthographic_projection_matrix(camera);
        glUniformMatrix4fv(projection_loc, 1, true, *projection_from_view._11);
    }

    {
        mode_loc := glGetUniformLocation(mesh_shader, "display_mode");
        glUniform1i(mode_loc, xx info.display_mode);
    }

    {
        loc := glGetUniformLocation(mesh_shader, "wave");
        wave := ifx info.flash_wave_dt == 0 then -1 else cos(5 * info.flash_wave_dt);
        glUniform1f(loc, wave);
    }

    {
        color_loc := glGetUniformLocation(mesh_shader, "color");
        glUniform4f(color_loc, info.color.x, info.color.y, info.color.z, info.color.w);
    }

    {
        point_size_loc := glGetUniformLocation(mesh_shader, "point_size");
        glUniform1f(point_size_loc, xx style.point_size);
    }

    {
        loc := glGetUniformLocation(mesh_shader, "camera.eye_position");
        glUniform3f(loc, camera.eye_position.x, camera.eye_position.y, camera.eye_position.z);
    }

    glBindVertexArray(mesh_vao);
    glBindBuffer(GL_ARRAY_BUFFER, info.vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, info.ibo);

    ATTRIB_POSITION  :: 0;
    ATTRIB_NORMAL    :: 1;

    glEnableVertexAttribArray(ATTRIB_POSITION);
    glEnableVertexAttribArray(ATTRIB_NORMAL);
    defer glDisableVertexAttribArray(ATTRIB_POSITION);
    defer glDisableVertexAttribArray(ATTRIB_NORMAL);

    // ATTRIB_TEXCOORDS :: 1;
    // ATTRIB_COLOR     :: 2;

    NP := size_of(Vector3) * mesh.positions.count;

    glVertexAttribPointer(ATTRIB_POSITION, 3, GL_FLOAT, false, size_of(Vector3), null);
    glVertexAttribPointer(ATTRIB_NORMAL, 3, GL_FLOAT, false, size_of(Vector3), cast(*void)(NP));

    last_line_width: float;
    glGetFloatv(GL_LINE_WIDTH, xx *last_line_width);
    defer glLineWidth(last_line_width);

    glLineWidth(xx style.line_width); // 1, 2, 3... See also glEnable(GL_LINE_SMOOTH);

    last_polygon_mode: [2]GLuint;
    glGetIntegerv(GL_POLYGON_MODE, xx last_polygon_mode.data);
    defer glPolygonMode(GL_FRONT_AND_BACK, last_polygon_mode[0]);

    if info.wireframe {
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    } else {
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    }

    if #complete mesh.geometry_format == {
        case .POINTS;
        case .UNKNOWN;
        case .LINES;
            glDrawElements(GL_LINES, xx mesh.indices.count, GL_UNSIGNED_INT, null);
        case .TRIANGLES;
            glDrawElements(GL_TRIANGLES, xx mesh.indices.count, GL_UNSIGNED_INT, null);
    }

    glEnable(GL_PROGRAM_POINT_SIZE);
    glDrawArrays(GL_POINTS, 0, xx mesh.positions.count);
}

render_vertex_labels :: (points : []$T, style : VertexLabelStyle, label_index_offset : int = 0) {
    #assert(T == Vector2 || T == Vector3);
    dim :: #run dimension_of(T);

    if !style.show_index && !style.show_position {
        return;
    }

    glEnable(GL_BLEND);
    defer glDisable(GL_BLEND);
    // Culling is unhelpful for polygon meshes @Cleanup make this a property on the mesh
    // glDisable(GL_CULL_FACE);
    // defer glEnable(GL_CULL_FACE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    world_from_model := matrix4_identity();
    projection_from_model := make_projection_from_world(app.camera) * world_from_model;

    new_context := context;
    push_context new_context {
        format_float := *context.print_style.default_format_float;
        <<format_float = style.format_float;

        // @TODO call render_text_quad once with a list of points
        for points {
            text : string;
#if dim == 2 {
            if  style.show_index && style.show_position text = tprint("% (%, %)", label_index_offset + it_index, it.x, it.y);
            if !style.show_index && style.show_position text = tprint("(%, %)", it.x, it.y);
} else {
            if  style.show_index && style.show_position text = tprint("% (%, %, %)", label_index_offset + it_index, it.x, it.y, it.z);
            if !style.show_index && style.show_position text = tprint("(%, %, %)", it.x, it.y, it.z);
}
            if  style.show_index && !style.show_position text = tprint("%", label_index_offset + it_index);
            if !style.show_index && !style.show_position break;

            text_w := get_text_width_in_pixels(text, 1.0);

            // [-1, 1]x[-1,1] -> [0, current_window_width]x[0, current_window_height]
#if dim == 2 {
            text_position_px := projection_from_model * make_vector4(it.x, it.y, 0, 1.);
} else {
            text_position_px := projection_from_model * make_vector4(it.x, it.y, it.z, 1.);
}
            text_position_px.x = cast(float)app.current_window_width * (text_position_px.x + 1) / 2;
            text_position_px.y = cast(float)app.current_window_height * (text_position_px.y + 1) / 2;

            render_text_quad(app.text_shader, text, text_position_px.xy, style.label_scale, style.label_color);
        }
    }
}

debug_print_active_uniforms :: (shader : GLuint) {
    using app;

    max_length: GLint;
    glGetProgramiv(mesh_shader, GL_ACTIVE_UNIFORM_MAX_LENGTH, *max_length);
    name := alloc_string(max_length);
    defer free(name);
    // print("GL_ACTIVE_UNIFORM_MAX_LENGTH = %\n", max_length);

    count : s32;
    glGetProgramiv(shader, GL_ACTIVE_UNIFORMS, *count);
    print("[debug %] Shader % has % active uniforms:\n", #location(), shader, count);
    for 0..count-1 {
        size: GLint;
        type: GLenum;
        length: GLsizei;

        glGetActiveUniform(shader, cast(GLuint) it, xx max_length, *length, *size, *type, name.data);
        name.count = xx length;
        print("Uniform #% Type: 0x% Size: % Name: %\n", it, formatInt(type, base=16), size, name);
    }
}

print_errors :: (loc := #caller_location) {
    DumpGLErrors("context %", #location());

    {
        error := glGetError();
        if (error != GL_NO_ERROR) {
            print("error:%:%,%: code % (%)\n", loc.fully_pathed_filename, loc.line_number, loc.character_number, error, formatInt(error, base=16));
            print("stack trace\n");
            for pack_stack_trace() {
                print_stack_trace(*it);
            }
            exit(-1);
        }
    }
}

debug_callback :: (source: GLenum, type: GLenum, id: GLuint, severity: GLenum, length: GLsizei, message: *u8, userParam: *void) #c_call {
    pctx := cast(*Context) userParam;
    ctx := <<pctx;
    push_context ctx {
        print("source: %\n", source);
        print("type: %\n", type);
        print("id: %\n", id);
        print("severity: %\n", severity);
        print("length: %\n", length);
        print("message: %\n", message);
        print("userParam: %\n", userParam);
    }
}

debug_vector :: (length : float, vector_world : Vector3, color : Vector4) {
    debug_mesh_ps := make_axis_arrow(length);
    defer deinit(debug_mesh_ps);

    par_shapes_rotate(debug_mesh_ps, angle(Vector3.{0,0,1}, unit_vector(vector_world)), unit_vector(cross_product(Vector3.{0,0,1}, unit_vector(vector_world))));
    par_shapes_translate(debug_mesh_ps, app.camera.look_position);

    debug_mesh := to_Mesh(debug_mesh_ps);
    defer deinit(*debug_mesh);

    // @Cleanup: struct literals do not currently support non-constant values
    display_info : Display_Info;
    display_info.wireframe = true;
    display_info.color = color;

    buffer_mesh(*debug_mesh, *display_info);

    render_mesh(debug_mesh, display_info, .{point_size=0, line_width=1});
}

debug_text_at_cursor :: (text : string)
{
    glEnable(GL_BLEND);
    defer glDisable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    text_w := get_text_width_in_pixels(text, 1.0);
    scale := 0.5;
    render_text_quad(app.text_shader,
                     text,
                     // make_vector2(25.0, WINDOW_HEIGHT - FONT_SIZE * scale),
                     make_vector2(io().MousePos.x, app.current_window_height - io().MousePos.y),
                     scale,
                     make_vector4(1., 1., 1., 1));
}

get_shader_program :: (shader_vertex : string, shader_fragment : string) -> GLuint {
    make_shader_object :: (shader : string, shader_type : GLenum) -> GLuint {
        shader_object := glCreateShader(shader_type);

        //shader_str := temp_c_string(shader);
		length : GLint = xx shader.count;
        glShaderSource(shader_object, 1, *shader.data, *length);

        glCompileShader(shader_object);

        success : GLint;
        glGetShaderiv(shader_object, GL_COMPILE_STATUS, *success);

        if !success then {
            log : [512] u8;
            glGetShaderInfoLog(shader_object, 512, null, log.data);
            print("[Shader] %\n", to_string(log.data));
            exit(1); // Hard-exit for now.
        }

        return shader_object;
    }

    shader_v := make_shader_object(shader_vertex, GL_VERTEX_SHADER);
    shader_f := make_shader_object(shader_fragment, GL_FRAGMENT_SHADER);
    shader_p := glCreateProgram();

    glAttachShader(shader_p, shader_v);
    glAttachShader(shader_p, shader_f);
    glLinkProgram(shader_p);

    success : GLint = 0;
    glGetProgramiv(shader_p, GL_LINK_STATUS, *success);

    if !success then {
        BUFFER_SIZE_LOG :: 512;
        log : [BUFFER_SIZE_LOG] u8;
        glGetProgramInfoLog(shader_p, BUFFER_SIZE_LOG, null, log.data);
        print("[Shader] %\n", to_string(log.data));
        exit(1); // Hard-exit for now.
    } 

    glDeleteShader(shader_v);
    glDeleteShader(shader_f);

    return shader_p;
}