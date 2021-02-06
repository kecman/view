// Shared global state is stored here
app : struct {
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

    show_ui := true;
    show_console_ui := false;

    camera : Camera;
    console : Console;
}

current_window_aspect_ratio_width_over_height :: () -> float {
    return cast(float) app.current_window_width / cast(float) app.current_window_height;
}

main :: () {

    // my_logger :: (message: string, ident: string, mode: Log_Mode, data: *void) {
    //     print("my_logger: [%] %", ident, message);
    // }
    // context.logger = my_logger; // default is no-op so need to set our own

    SDL_Init(SDL_INIT_VIDEO);

    window := SDL_CreateWindow(tprint("View v%", VIEW_VERSION_STRING).data,
                               SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                               app.INITIAL_WINDOW_WIDTH, app.INITIAL_WINDOW_HEIGHT,
                               SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

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
        vert :: #run read_entire_file("src/shaders/text.vert");
        frag :: #run read_entire_file("src/shaders/text.frag");
        app.text_shader = get_shader_program(vert, frag);
    }

    // Prepare VAO for text quads.
    {
        glGenVertexArrays(1, *app.text_vao);
        glGenBuffers(1, *app.text_vbo);
        glBindVertexArray(app.text_vao);
        glBindBuffer(GL_ARRAY_BUFFER, app.text_vbo);
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
        app.mesh_shader = get_shader_program(vert, frag);
    }

    // Prepare VAO for lines
    {
        glGenVertexArrays(1, *app.polyline_vao);
        glGenVertexArrays(1, *app.mesh_vao);
    }

    triad := make_axes_triad(10);

    vertex_label_style : VertexLabelStyle;

    init_font();
    init_commands();

    ImGui.CreateContext();
    ImGui_ImplSdl_Init(window);

    if false {
        position := make_vector2(0, 0);
        ImGui.SetWindowPos(pos=*position);
    }

    // Setup style
    // ImGui.StyleColorsClassic();
    // ImGui.StyleColorsLight();
    ImGui.StyleColorsDark();

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
                case SDL_WINDOWEVENT;
                    if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {

                        width_scale := cast(float) event.window.data1 / app.current_window_width;
                        height_scale := cast(float) event.window.data2 / app.current_window_height;

                        camera_delta_rl := (1. - width_scale) * (app.camera.right - app.camera.left) / 2;
                        camera_delta_tb := (1. - height_scale) * (app.camera.top - app.camera.bottom) / 2;
                        app.camera.right -= camera_delta_rl;
                        app.camera.left += camera_delta_rl;
                        app.camera.top -= camera_delta_tb;
                        app.camera.bottom += camera_delta_tb;

                        app.current_window_width = event.window.data1;
                        app.current_window_height = event.window.data2;
                    }
                case SDL_KEYDOWN; {
                    if event.key.keysym.sym == SDLK_BACKQUOTE {
                        if SDL_GetModState() & KMOD_CTRL {
                            app.show_ui = !app.show_ui;
                        } else {
                            app.show_console_ui = !app.show_console_ui;
                        }
                    }
                }
                case SDL_KEYUP; {
                    if event.key.keysym.sym == SDLK_ESCAPE done = true;
                    if event.key.keysym.sym == SDLK_r fit_on_screen();
                    if event.key.keysym.sym == SDLK_v cycle_vertex_label_style(*vertex_label_style);
                    if event.key.keysym.sym == SDLK_l cycle_line_style(*vertex_label_style);

                    if event.key.keysym.sym == SDLK_RIGHTBRACKET {
                        amount : float = 45;
                        if SDL_GetModState() & KMOD_SHIFT amount = 15;
                        app.camera.up_direction.xy = rotate(app.camera.up_direction.xy, to_radians(amount));
                    }
                    if event.key.keysym.sym == SDLK_LEFTBRACKET {
                        amount : float = 45;
                        if SDL_GetModState() & KMOD_SHIFT amount = 15;
                        app.camera.up_direction.xy = rotate(app.camera.up_direction.xy, to_radians(-amount));
                    }
                }
                case SDL_DROPFILE; {
                    // @Cleanup event.drop.file should be free'd using SDL_free
                    dropped := to_string(event.drop.file);

                    skip := false;
                    for entities {
                        mesh := get_mesh(it);
                        if mesh && mesh.fully_pathed_filename == dropped {
                            skip = true;
                            break;
                        }
                    }
                    if skip {
                        print("Skipped file: '%' (already loaded)\n", dropped);
                        continue;
                    }

                    mesh := load_obj(dropped);

                    if #complete mesh.geometry_format == {
                        case .LINES;
                            shape, ok := to_Polyline_Soup2(mesh);
                            assert(ok);

                            entity := New(Polyline_Soup2_Entity);
                            entity.mesh = mesh;
                            entity.shape = shape;
                            array_add(*entities, entity);

                            logprint("view","Loaded 2d polyline soup file: '%'\n", dropped);
                            fit_on_screen();

                        case .TRIANGLES;
                            entity := New(Mesh_Entity);
                            entity.mesh = mesh;
                            array_add(*entities, entity);
                            logprint("view", "Loaded triangle mesh file: '%'\n", dropped);

                        case .POINTS; #through;
                        case .UNKNOWN; #through;
                        case;
                            logprint("view", "Skipped file: '%' (unsupported geometry type %)\n", dropped, mesh.geometry_format);
                            deinit(*mesh);
                            continue; // @Incomplete: support polygon types using wkt format
                    }
                }
            }
        }

        ImGui.GetStyle().WindowRounding = 0;
        ImGui_ImplSdl_NewFrame(window);

        if app.show_ui {
            ImGui.SetNextWindowPos(pos=*make_vector2(10, 10), pivot=*make_vector2(0,0));
            ImGui.Begin("", flags = ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
            ImGui.ColorEdit4("Canvas", *clear_color.component, ImGui.ColorEditFlags.NoInputs);
            ImGui.SameLine();
            ImGui.Checkbox("World Axes", *triad.origin.visible);
            set_visibility(*triad, triad.origin.visible);


            #if false {
                if ImGui.Button("Demo Window", size=*make_vector2(0,0)) show_demo_window ^= true;
                if show_demo_window {
                    ImGui.SetNextWindowPos(*make_vector2(650, 20), ImGui.Cond.FirstUseEver, *make_vector2(0,0));
                    ImGui.ShowDemoWindow(*show_demo_window);
                }
            }

            if ImGui.Button("Reset Window          ", size=*make_vector2(0,0)) SDL_SetWindowSize(window, app.INITIAL_WINDOW_WIDTH, app.INITIAL_WINDOW_HEIGHT);
            if ImGui.Button("Reset Camera       (R)", size=*make_vector2(0,0)) fit_on_screen();
            if ImGui.Button("Cycle vertex style (V)", size=*make_vector2(0,0)) cycle_vertex_label_style(*vertex_label_style);
            if ImGui.Button("Cycle line style   (L)", size=*make_vector2(0,0)) cycle_line_style(*vertex_label_style);

            imgui_label :: (label : string, ptr : *void) -> *u8 {
                return to_c_string(concatenate(label, tprint("##%", ptr)));
            }

            entity_to_remove := -1;
            for entities {
                mesh := get_mesh(it);
                if mesh {
                    ImGui.Text(to_c_string(tprint("%", it_index)));
                    ImGui.SameLine();
                    if ImGui.Button(imgui_label("Remove", it), size=*make_vector2(0, 0)) {
                        entity_to_remove = it_index;
                        break;
                    }
                    ImGui.SameLine();
                    ImGui.ColorEdit4(imgui_label("##color", it), *mesh.color.component, ImGui.ColorEditFlags.NoInputs);
                    ImGui.SameLine();
                    ImGui.Checkbox(imgui_label("##visible", it), *mesh.visible);
                    if it.type == .MESH {
                        ImGui.SameLine();
                        ImGui.Checkbox(imgui_label("##wireframe", it), *mesh.wireframe);
                    }
                    ImGui.SameLine();
                    ImGui.Text(path_filename(mesh.fully_pathed_filename));
                }
            }

            if entity_to_remove >= 0 && entity_to_remove < entities.count {
                deinit(entities[entity_to_remove]);
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

        #if false {
            debug_print_active_uniforms(app.text_shader);
            debug_print_active_uniforms(app.mesh_shader);
        }

        // Rendering
        glViewport(0, 0, xx io().DisplaySize.x, xx io().DisplaySize.y); // @TODO Is DisplaySize updated with window resizing? Use current_window_height/width here?
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glEnable(GL_DEPTH_TEST);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);

        // Update after clearing viewport so we can debug visualise stuff
        // @Cleanup: use delta_time argument?
        update_camera(1);

        for entities {
            mesh := get_mesh(it);
            if mesh && mesh.visible {
                render_mesh(<<mesh, vertex_label_style);
                // @Cleanup so the transform is also available for text rendering
                render_vertex_labels(mesh.vertices, vertex_label_style);
            }
        }

        render_mesh(triad.origin, .{point_size=0, line_width=1});
        render_mesh(triad.x_axis, .{point_size=0, line_width=1});
        render_mesh(triad.y_axis, .{point_size=0, line_width=1});
        render_mesh(triad.z_axis, .{point_size=0, line_width=1});

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
            render_text_quad(app.text_shader,
                             text,
                             // make_vector2(25.0, WINDOW_HEIGHT - FONT_SIZE * scale),
                             make_vector2(io().MousePos.x, app.current_window_height - io().MousePos.y),
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

#import "Basic";
#import "File";
#import "String";
#import "Math";

geom :: #import "geometry";
#import "BoostPolygon";

#load "io.jai";
#load "shaders.jai";
#load "font.jai";
#load "carpet.jai";
#load "camera.jai";
#load "console.jai";
#load "entities.jai";
#load "mesh_utils.jai";
//#load "commands.jai"; // @CompilerBug loading here triggers incorrect (?) compilation error

#scope_file

render_mesh :: (mesh : Mesh, style : VertexLabelStyle) {
    using app;

    if !mesh.visible {
        return;
    }

    assert(!mesh.is_dirty);

    glUseProgram(mesh_shader);

    projection_from_model := make_projection_from_world(app.camera) * mesh.world_from_model;

    mvp_loc := glGetUniformLocation(mesh_shader, "mvp");
    color_loc := glGetUniformLocation(mesh_shader, "color");
    point_size_loc := glGetUniformLocation(mesh_shader, "point_size");

    glUniformMatrix4fv(mvp_loc, 1, GL_TRUE, *projection_from_model._11);
    glUniform4f(color_loc, mesh.color.x, mesh.color.y, mesh.color.z, mesh.color.w);
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
    projection_from_model := make_projection_from_world(app.camera) * world_from_model;

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
        text_position_px := projection_from_model * make_vector4(it.x, it.y, it.z, 1.);
        text_position_px.x = cast(float)app.current_window_width * (text_position_px.x + 1) / 2;
        text_position_px.y = cast(float)app.current_window_height * (text_position_px.y + 1) / 2;

        render_text_quad(app.text_shader, text, text_position_px.xy, scale, make_vector4(1., 1., 1., 1));
    }
}

fit_on_screen :: () {
    view_from_world := make_look_at_matrix(app.camera);
    world_from_view := inverse(view_from_world);

    // Compute the bounding box of the scene in view coords
    bbox_view : geom.AxisBox3;
    for entities {
        mesh := get_mesh(it);
        if mesh && mesh.visible {
            view_from_model := view_from_world * mesh.world_from_model;

            mesh_bbox_view : AxisBox3;
            for point_model : mesh.vertices {
                point_view := (view_from_model * make_vector4(point_model, 1)).xyz;
                expand(*mesh_bbox_view, point_view);
            }
            expand(*bbox_view, mesh_bbox_view);
        }
    }

    if geom.is_empty(bbox_view) {
        init_camera(); // Reset to initial view
        return;
    }

    // Offset by a bit so the geometry doesn't end right on window boundaries
    geom.offset(*bbox_view, 0.05 * geom.extents(bbox_view));

    center_world := (world_from_view * make_vector4(geom.center_point(bbox_view), 1)).xyz;
    app.camera.look_position = center_world;

    extents := geom.extents(bbox_view);
    scale := (extents.y / 2) / app.camera.top;
    if scale * app.camera.right < (extents.x / 2) {
        scale = (extents.x / 2) / app.camera.right;
    }

    app.camera.top *= scale;
    app.camera.bottom *= scale;
    app.camera.right *= scale;
    app.camera.left *= scale;

    // @TODO pick these numbers so details at 5um are clearly visible e.g., fill up whole screen?
    app.camera.top = max(app.camera.top, 0.1);
    app.camera.bottom = min(app.camera.bottom, -0.1);
    app.camera.right = max(app.camera.right, current_window_aspect_ratio_width_over_height() * 0.1);
    app.camera.left = min(app.camera.left, -current_window_aspect_ratio_width_over_height() * 0.1);;
}

VertexLabelStyle :: struct {
    show_position := false;
    show_index := false;

    point_size : int = 4; // 0, 2, 4, 6
    line_width : int = 2; // 1, 1, 2, 3
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

#load "vendor/imgui_sdl_gl.jai";

#import "Compiler";
// #run compiler_set_type_info_flags(GL_Procedures, .PROCEDURES_ARE_VOID_POINTERS);
// #run compiler_set_type_info_flags(ImGui, .PROCEDURES_ARE_VOID_POINTERS);
#run compiler_set_type_info_flags(GL_Procedures, .NO_SIZE_COMPLAINT);
#run compiler_set_type_info_flags(ImGui, .NO_SIZE_COMPLAINT);
