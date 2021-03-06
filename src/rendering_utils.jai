debug_print_active_uniforms :: (program : GLuint) {

    max_length: GLint;
    glGetProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH, *max_length);
    name := alloc_string(max_length);
    defer free(name);
    // print("GL_ACTIVE_UNIFORM_MAX_LENGTH = %\n", max_length);

    count : s32;
    glGetProgramiv(program, GL_ACTIVE_UNIFORMS, *count);
    print("[debug %] Program % has % active uniforms:\n", #location(), program, count);
    for 0..count-1 {
        size: GLint;
        type: GLenum;
        length: GLsizei;

        glGetActiveUniform(program, cast(GLuint) it, xx max_length, *length, *size, *type, name.data);
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
    display_info.wireframe_visible = true;
    display_info.wireframe_width = 1;
    display_info.surface_color = color;
    display_info.points_size = 0;

    render_info : Render_Info;
    render_mesh_triangles(*debug_mesh, *render_info, display_info);
}

debug_text_at_cursor :: (text : string, scale := .5, color : Vector4 = .{1, 1, 1, 1}) {
    glEnable(GL_BLEND);
    defer glDisable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    text_w := get_text_width_in_pixels(text, 1.0);
    render_text_quad(app.text_program,
                     text,
                     // make_vector2(25.0, WINDOW_HEIGHT - FONT_SIZE * scale),
                     make_vector2(io().MousePos.x, app.current_window_height - io().MousePos.y),
                     scale,
                     color);
}

get_shader_program :: (shader_vertex : string, shader_fragment : string, shader_geometry : string = "") -> GLuint {

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

    program := glCreateProgram();

    shader_v := make_shader_object(shader_vertex, GL_VERTEX_SHADER);
    glAttachShader(program, shader_v);

    shader_g : GLuint;
    if shader_geometry.count {
        shader_g = make_shader_object(shader_geometry, GL_GEOMETRY_SHADER);
        glAttachShader(program, shader_g);
    }

    shader_f := make_shader_object(shader_fragment, GL_FRAGMENT_SHADER);
    glAttachShader(program, shader_f);

    glLinkProgram(program);

    success : GLint = 0;
    glGetProgramiv(program, GL_LINK_STATUS, *success);

    if !success then {
        BUFFER_SIZE_LOG :: 512;
        log : [BUFFER_SIZE_LOG] u8;
        glGetProgramInfoLog(program, BUFFER_SIZE_LOG, null, log.data);
        print("[Shader] %\n", to_string(log.data));
        exit(1); // Hard-exit for now.
    }

    glDeleteShader(shader_v);
    glDeleteShader(shader_f);
    if shader_geometry.count {
        glDeleteShader(shader_g);
    }

    return program;
}