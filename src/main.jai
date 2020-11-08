#import "Basic";
#import "File";
#import "String";
#import "Math";

#load "vendor/imgui_sdl_gl.jai";

geom :: #import "geometry"; // @Cleanup just load this
#import "BoostPolygon";

#load "io.jai";
#load "shaders.jai";
#load "font.jai";
#load "camera.jai";
#load "console.jai";
#load "entities.jai";
//#load "commands.jai"; // @CompilerBug? loading this here and console.jai causes:Error: Redeclaration of variable 'command_list'. but I think this should work? Hmmm

//#import "Debug";

INITIAL_WINDOW_WIDTH  : s32 : 1280;
INITIAL_WINDOW_HEIGHT : s32 : 720;

current_window_width := INITIAL_WINDOW_WIDTH;
current_window_height := INITIAL_WINDOW_HEIGHT;

text_shader : GLuint;
text_vao : GLuint;
text_vbo : GLuint;

mesh_shader : GLuint;
mesh_vao : GLuint;
polyline_shader : GLuint;
polyline_vao : GLuint;

show_ui := true;    // Wish we could declare static variables inside functions.

// @TODO move this into the polyine struct
VertexLabelStyle :: struct {
    show_position := false;
    show_index := false;

    point_size : int = 4; // 0, 2, 4, 6
    line_width : int = 2; // 1, 1, 2, 3
}

render_mesh :: (mesh : Mesh, style : VertexLabelStyle) {

    if !mesh.visible {
        return;
    }

    assert(mesh.is_dirty == false);

    glUseProgram(mesh_shader);

    color_loc := glGetUniformLocation(mesh_shader, "color");
    glUniform4f(color_loc, mesh.color.x, mesh.color.y, mesh.color.z, mesh.color.w);
    point_size_loc := glGetUniformLocation(mesh_shader, "point_size");
    glUniform1f(point_size_loc, xx style.point_size);

    glBindVertexArray(mesh_vao);
    glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ibo);

    glEnableVertexAttribArray(0);
    defer glDisableVertexAttribArray(0);

    glVertexAttribPointer(0, 3, GL_FLOAT, false, size_of(Vector3), null);

    last_line_width: float;
    glGetFloatv(GL_LINE_WIDTH, xx *last_line_width);
    defer glLineWidth(last_line_width);

    glLineWidth(xx style.line_width); // 1, 2, 3... See also glEnable(GL_LINE_SMOOTH);

    last_polygon_mode: [2]GLuint;
    glGetIntegerv(GL_POLYGON_MODE, xx last_polygon_mode.data);
    defer glPolygonMode(GL_FRONT_AND_BACK, last_polygon_mode[0]);
    
    if mesh.wireframe {
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
    glDrawArrays(GL_POINTS, 0, xx mesh.vertices.count);
}

render_vertex_labels :: (points : []Vector3, style : VertexLabelStyle, label_index_offset : int = 0) {
    glEnable(GL_BLEND);
    defer glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    defer glEnable(GL_CULL_FACE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    world_from_model := matrix4_identity();
    view_from_world := make_look_at_matrix(*camera);
    projection_from_view := make_orthographic_projection_matrix(*camera);
    projection_from_model := projection_from_view * view_from_world * world_from_model;

    // @TODO call render_text_quad once with a list of points
    for points {
        text : string;
        if style.show_index && style.show_position text = tprint("% (% %)", label_index_offset + it_index, it.x, it.y);
        if style.show_index && !style.show_position text = tprint("%", label_index_offset + it_index);
        if !style.show_index && style.show_position text = tprint("(% %)", it.x, it.y);
        if !style.show_index && !style.show_position break;

        text_w := get_text_width_in_pixels(text, 1.0);
        scale := 0.3;

        // [-1, 1]x[-1,1] -> [0, current_window_width]x[0, current_window_height]
        text_position_px := projection_from_model * make_vector4(it.x, it.y, 0., 1.);
        text_position_px.x = cast(float)current_window_width * (text_position_px.x + 1) / 2;
        text_position_px.y = cast(float)current_window_height * (text_position_px.y + 1) / 2;

        render_text_quad(text_shader, text, text_position_px.xy, scale, make_vector4(1., 1., 1., 1));
    }
}

MouseState :: struct {
    position_px : Vector2;
    velocity_px : Vector2;
    wheel :       float;
    left_down :   bool;
    right_down :  bool;
    middle_down : bool;
}

die :: (loc := #caller_location) {
    print("exit(1) at %:%\n", loc.fully_pathed_filename, loc.line_number);
    exit(1);
}

main :: () {

    // my_logger :: (message: string, ident: string, mode: Log_Mode, data: *void) {
    //     print("my_logger: [%] %", ident, message);
    // }
    // context.logger = my_logger; // default is no-op so need to set our own

    SDL_Init(SDL_INIT_VIDEO);

    window := SDL_CreateWindow(tprint("View v%", VIEW_VERSION_STRING).data, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    // Check that the window was successfully created
    if window == null {
        // In the case that the window could not be made...
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    // print("%\n", to_string(ImGui.GetVersion()));

    // @FIXME If I don't explicitly set attributes here gl_get_version() returns a different result
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 6);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(window);
    if !gl_context {
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }

    gl_load(*gl, SDL_GL_GetProcAddress);

    // @TODO enable these for debug builds?
    // gl_enable_debug_output(true);
    // glEnable(GL_DEBUG_OUTPUT); // @FIXME above enables GL_DEBUG_OUTPUT_SYNCHRONOUS, but without this line debug output doesn't work

    // opengl_major_version, opengl_minor_version : s32;
    // SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, *opengl_major_version);
    // SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, *opengl_minor_version);
    // print("OpenGL Version %.%\n", opengl_major_version, opengl_minor_version);

    gl_version_major, gl_version_minor = gl_get_version();
    print ("OpenGL %.%\n", gl_version_major, gl_version_minor);

    init_camera();

    // OGL Options
    {
    }

    // Setup text shader
    {
        projection := orthographic_projection_matrix(0.0, xx current_window_width, 0.0, xx current_window_height, -1.0, 1.0);
        mvp := projection;

        vert :: #run read_entire_file("src/shaders/text.vert");
        frag :: #run read_entire_file("src/shaders/text.frag");
        text_shader = get_shader_program(vert, frag);

        glUseProgram(text_shader);
        mvp_loc := glGetUniformLocation(text_shader, "mvp");
        glUniformMatrix4fv(mvp_loc, 1, GL_TRUE, *mvp._11);
    }

    // Prepare VAO for text quads.
    {
        glGenVertexArrays(1, *text_vao);
        glGenBuffers(1, *text_vbo);
        glBindVertexArray(text_vao);
        glBindBuffer(GL_ARRAY_BUFFER, text_vbo);
        glBufferData(GL_ARRAY_BUFFER, size_of(GLfloat) * 6 * 4, null, GL_DYNAMIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 4 * size_of(GLfloat), xx 0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
    }

    // Setup mesh shader
    {
        vert :: #run read_entire_file("src/shaders/mesh.vert");
        frag :: #run read_entire_file("src/shaders/mesh.frag");
        mesh_shader = get_shader_program(vert, frag);
    }

    // Prepare VAO for lines
    {
        glGenVertexArrays(1, *polyline_vao);
        glGenVertexArrays(1, *mesh_vao);
    }

    /*
    test_mesh : geom.Mesh;
    {
        array_add(*test_mesh.vertices, .{0, 0, 0});
        array_add(*test_mesh.vertices, .{5, 0, 0});
        array_add(*test_mesh.vertices, .{5, 5, 0});
        array_add(*test_mesh.vertices, .{0, 5, 0});
        for test_mesh.vertices print("vertex [%] %\n", it_index, it);

        array_add(*test_mesh.indices, 0); array_add(*test_mesh.indices, 1);
        array_add(*test_mesh.indices, 1); array_add(*test_mesh.indices, 2);
        array_add(*test_mesh.indices, 2); array_add(*test_mesh.indices, 3);
        array_add(*test_mesh.indices, 3); array_add(*test_mesh.indices, 4);
        for test_mesh.indices print("index [%] %\n", it_index, it);

        test_mesh.geometry_format = .LINES;
        geom.buffer_mesh(*test_mesh);
        print("mesh %\n", test_mesh);
    }
    */

    vertex_label_style : VertexLabelStyle;

    {
        // This should be dynamic, depending on the camera etc
        world_from_model := matrix4_identity();
        view_from_world := make_look_at_matrix(*camera);
        projection_from_view := make_orthographic_projection_matrix(*camera);

        projection_from_model := projection_from_view * view_from_world * world_from_model;

        glUseProgram(mesh_shader);
        mvp_loc := glGetUniformLocation(mesh_shader, "mvp");
        glUniformMatrix4fv(mvp_loc, 1, GL_TRUE, *projection_from_model._11);
    }


    init_font();
    init_commands();

    ImGui.CreateContext();
    // Setup ImGui binding
    ImGui_ImplSdl_Init(window);

    if false {
        position := make_vector2(0, 0);
        ImGui.SetWindowPos(pos=*position);
    }

    // Setup style
    // ImGui.StyleColorsClassic();
    // ImGui.StyleColorsLight();
    ImGui.StyleColorsDark();

    imgui_io := ImGui.GetIO();

    show_demo_window := false;
    // clear_color := make_vector4(0.45, 0.55, 0.60, 1.00);
    // clear_color := make_vector4(87./256, 194./256, 248./256, 1.00); // light blue
    clear_color := make_vector4(170./256, 170./256, 170./256, 1.00); // light grey

    // cursor_text := alloc_string(16);
    // defer free(cursor_text);
    // cursor_text.data[cursor_text.count] = 0;
    // cursor_text:="hello";

    // Main loop
    done := false;
    while !done {
        // You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
        // - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
        // - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
        // Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
        event: SDL_Event;
        while SDL_PollEvent(*event) {
            ImGui_ImplSdl_ProcessEvent(*event);
            if event.type == {
                case SDL_QUIT; {
                    done = true;
                }
                case SDL_KEYUP; {
                    if event.key.keysym.sym == SDLK_ESCAPE done = true;
                    if event.key.keysym.sym == SDLK_r fit_on_screen();
                    if event.key.keysym.sym == SDLK_v cycle_vertex_label_style(*vertex_label_style);
                    if event.key.keysym.sym == SDLK_l cycle_line_style(*vertex_label_style);

                    if event.key.keysym.sym == SDLK_RIGHTBRACKET {
                        amount : float = 45;
                        if SDL_GetModState() & KMOD_SHIFT amount = 15;
                        camera.up_direction.xy = rotate(camera.up_direction.xy, to_radians(amount));
                    }
                    if event.key.keysym.sym == SDLK_LEFTBRACKET {
                        amount : float = 45;
                        if SDL_GetModState() & KMOD_SHIFT amount = 15;
                        camera.up_direction.xy = rotate(camera.up_direction.xy, to_radians(-amount));
                    }
                }
                case SDL_DROPFILE; {
                    dropped := to_string(event.drop.file);

                    skip := false;
                    for entities {
                        if #complete it.type == {
                        case .POLYLINE_SOUP2; {
                            entity := cast(*Polyline_Soup2_Entity)it;
                            if entity.mesh.fully_pathed_filename == dropped {
                                skip = true;
                                break;
                            }
                        }
                        case .POLYGON_SOUP2; {
                            entity := cast(*Polygon_Soup2_Entity)it;
                            if entity.mesh.fully_pathed_filename == dropped {
                                skip = true;
                                break;
                            }
                        }
                        case .MESH; {
                            entity := cast(*Mesh_Entity)it;
                            if entity.mesh.fully_pathed_filename == dropped {
                                skip = true;
                                break;
                            }
                        }
                        case .UNKNOWN; {}
                        case .FLOAT; {}
                        }
                    }
                    if skip {
                        print("Skipped file: '%' (already loaded)\n", dropped);
                        continue;
                    }

                    mesh := load_obj(dropped);
                    if mesh.geometry_format != .LINES {
                        print("Skipped file: '%' (only 2D polylines with constant z are supported)\n", dropped);
                        // :Cleanup_Construction_Destruction:
                        array_free(mesh.vertices);
                        array_free(mesh.indices);
                        continue; // @Incomplete: support polygon types using wkt format
                    }

                    // :Cleanup_Construction_Destruction:
                    // entity := make_entity_Polygon_Soup2(mesh, );
                    entity := New(Polyline_Soup2_Entity);
                    entity.type = .POLYLINE_SOUP2;
                    entity.mesh = mesh;
                    // entity.id = ...
                    geom.buffer_mesh(*entity.mesh);
                    entity.mesh.fully_pathed_filename = dropped;
                    ok : bool;
                    entity.shape, ok = to_Polyline_Soup2(mesh);
                    assert(ok);

                    print("Loaded file: '%'\n", dropped);

                    array_add(*entities, entity);

                    fit_on_screen();
                }
            }
        }
        ImGui_ImplSdl_NewFrame(window);

        {
            ImGui.SetNextWindowPos(pos=*make_vector2(10, 10), pivot=*make_vector2(0,0));
            ImGui.Begin("", *show_ui, ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
            ImGui.ColorEdit4("Background Color", clear_color.component, ImGui.ColorEditFlags.NoInputs);

            #if false {
                if ImGui.Button("Demo Window", size=*make_vector2(0,0)) show_demo_window ^= true;
                ImGui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / imgui_io.Framerate, imgui_io.Framerate);
                w, h : s32;
                SDL_GetWindowSize(window, *w, *h);
                ImGui.Text(tprint("Window size %1x%2", w, h));
                if show_demo_window {
                    ImGui.SetNextWindowPos(*make_vector2(650, 20), ImGui.Cond.FirstUseEver, *make_vector2(0,0));
                    ImGui.ShowDemoWindow(*show_demo_window);
                }
            }

            if ImGui.Button("Reset Window          ", size=*make_vector2(0,0)) SDL_SetWindowSize(window, INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT);
            if ImGui.Button("Reset Camera       (R)", size=*make_vector2(0,0)) fit_on_screen();
            if ImGui.Button("Cycle vertex style (V)", size=*make_vector2(0,0)) cycle_vertex_label_style(*vertex_label_style);
            if ImGui.Button("Cycle line style   (L)", size=*make_vector2(0,0)) cycle_line_style(*vertex_label_style);

            imgui_label :: (label : string, ptr : *void) -> c_string {
                return to_c_string(concatenate(label, tprint("##%", ptr)));
            }

            entity_to_remove := -1;
            for entities {
                mesh := get_mesh(it);
                if mesh {
                    ImGui.Text("%", it_index);
                    ImGui.SameLine();
                    ImGui.Checkbox(imgui_label(path_filename(mesh.fully_pathed_filename), it), *mesh.visible);
                    ImGui.SameLine();
                    ImGui.ColorEdit4(imgui_label("##color", it), mesh.color.component, ImGui.ColorEditFlags.NoInputs);
                    ImGui.SameLine();
                    ImGui.Checkbox(imgui_label("##wireframe", it), *mesh.wireframe);
                    ImGui.SameLine();
                    if ImGui.Button(imgui_label("Remove", it), size=*make_vector2(0, 0)) {
                        entity_to_remove = it_index;
                        break;
                    }
                }
            }

            if entity_to_remove >= 0 && entity_to_remove < entities.count {
                mesh := get_mesh(entities[entity_to_remove]);
                glDeleteBuffers(1, *mesh.vbo);
                glDeleteBuffers(1, *mesh.ibo);
                free(entities[entity_to_remove]);
                array_ordered_remove_by_index(*entities, entity_to_remove);
            }

            // @FIXME
            // if ImGui.InputText("Cursor Text", cursor_text.data, xx cursor_text.count) {
            //     // cursor_text.count = str_length(cursor_text.data);
            // }
            // ImGui.Text("%", cursor_text);

            ImGui.End();
        }

        console_draw();


        if ImGui.GetMouseCursor() == {
            case .Arrow;         SDL_SetCursor(cursor_arrow);
            case .TextInput;     SDL_SetCursor(cursor_text_input);
            case .Move;          SDL_SetCursor(cursor_move);
            case .ResizeNS;      SDL_SetCursor(cursor_resize_ns);
            case .ResizeEW;      SDL_SetCursor(cursor_resize_ew);
            case .ResizeNESW;    SDL_SetCursor(cursor_resize_nesw);
            case .ResizeNWSE;    SDL_SetCursor(cursor_resize_nwse);
        }

        mouse_state : MouseState;
        mouse_state.position_px = make_vector2(imgui_io.MousePos.x, imgui_io.MousePos.y);
        mouse_state.velocity_px = make_vector2(imgui_io.MouseDelta.x, imgui_io.MouseDelta.y);
        mouse_state.wheel = imgui_io.MouseWheel;
        mouse_state.left_down = imgui_io.MouseDown[0];
        mouse_state.right_down = imgui_io.MouseDown[1];
        mouse_state.middle_down = imgui_io.MouseDown[2];

        if !imgui_io.WantCaptureMouse {
            update_camera(*camera, 1, *mouse_state);
        }

        {
            world_from_model := matrix4_identity();
            view_from_world := make_look_at_matrix(*camera);
            projection_from_view := make_orthographic_projection_matrix(*camera);
            projection_from_model := projection_from_view * view_from_world * world_from_model;

            glUseProgram(mesh_shader);
            mvp_loc := glGetUniformLocation(mesh_shader, "mvp");
            glUniformMatrix4fv(mvp_loc, 1, GL_TRUE, *projection_from_model._11);
        }

        {
            SDL_GetWindowSize(window, *current_window_width, *current_window_height);
            projection := orthographic_projection_matrix(0.0, xx current_window_width, 0.0, xx current_window_height, -1.0, 1.0);

            // @fixme: this is broken, text is in the wrong position in y after resizing
            mvp := projection;
            glUseProgram(text_shader);
            mvp_loc := glGetUniformLocation(text_shader, "mvp");
            glUniformMatrix4fv(mvp_loc, 1, GL_TRUE, *mvp._11);
        }

        #if false {
            debug_print_active_uniforms(text_shader);
            debug_print_active_uniforms(mesh_shader);
        }

        // Rendering
        glViewport(0, 0, xx imgui_io.DisplaySize.x, xx imgui_io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
        for entities {
            mesh := get_mesh(it);
            if mesh && mesh.visible {
                render_mesh(<<mesh, vertex_label_style);
                render_vertex_labels(mesh.vertices, vertex_label_style);
            }
        }

        ImGui.Render();

        if false { // @Cleanup: remove this
            glEnable(GL_BLEND);
            defer glDisable(GL_BLEND);
            glDisable(GL_CULL_FACE); // LTB---will f-you up with triangles. if only 2d stuff just leave blending on
            defer glEnable(GL_CULL_FACE);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            text := "Hello";
            // text := cursor_text;
            text_w := get_text_width_in_pixels(text, 1.0);
            scale := 0.5;
            render_text_quad(text_shader,
                             text,
                             // make_vector2(25.0, WINDOW_HEIGHT - FONT_SIZE * scale),
                             make_vector2(imgui_io.MousePos.x, current_window_height - imgui_io.MousePos.y),
                             scale,
                             make_vector4(1., 1., 1., 1));
        }

        SDL_GL_SwapWindow(window);

        reset_temporary_storage();
    }

    // Cleanup
    ImGui_ImplSdl_Shutdown();
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

#scope_file

fit_on_screen :: () {
    overall_bounds : geom.AxisBox2;
    geom.init(*overall_bounds);
    for entities {
        mesh := get_mesh(it);
        if mesh && mesh.visible {
            bounds := geom.bounding_box(<<mesh);
            geom.expand(*overall_bounds, *bounds);
        }
    }

    geom.offset(*overall_bounds, 0.05 * geom.extents(*overall_bounds));
    update_to_fit_on_screen(*camera, *overall_bounds);
}

cycle_vertex_label_style :: (using style : *VertexLabelStyle) {
    if show_index && show_position show_position = false;
    else if show_index && !show_position show_index = false;
    else if !show_index && !show_position show_position = true;
    else show_index = true;
}

cycle_line_style :: (using style : *VertexLabelStyle) {
    if point_size == 0 && line_width == 1 {
        point_size = 2; line_width = 1;
    } else if point_size == 2 && line_width == 1 {
        point_size = 4; line_width = 2;
    } else if point_size == 4 && line_width == 2 {
        point_size = 6; line_width = 3;
    } else {
        point_size = 0; line_width = 1;
    }
}

debug_print_active_uniforms :: (shader : GLuint) {
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

#import "Compiler";
// #run compiler_set_type_info_flags(GL_Procedures, .PROCEDURES_ARE_VOID_POINTERS);
// #run compiler_set_type_info_flags(ImGui, .PROCEDURES_ARE_VOID_POINTERS);
#run compiler_set_type_info_flags(GL_Procedures, .NO_SIZE_COMPLAINT);
#run compiler_set_type_info_flags(ImGui, .NO_SIZE_COMPLAINT);
