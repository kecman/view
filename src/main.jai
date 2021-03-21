// Shared global state is stored here
app : struct {
    window : *SDL_Window = null;

    INITIAL_WINDOW_WIDTH  : s32 : 1280;
    INITIAL_WINDOW_HEIGHT : s32 : 720;

    current_window_width := INITIAL_WINDOW_WIDTH;
    current_window_height := INITIAL_WINDOW_HEIGHT;

    // clear_color := make_vector4(0.45, 0.55, 0.60, 1.00);
    // clear_color := make_vector4(87./256, 194./256, 248./256, 1.00); // light blue
    clear_color : Vector4 = .{170./256, 170./256, 170./256, 1.00}; // light grey

    text_shader : GLuint;
    text_vao : GLuint;
    text_vbo : GLuint;

    mesh_shader : GLuint;
    mesh_vao : GLuint;
    polyline_shader : GLuint;
    polyline_vao : GLuint;

    modifier_flags : Modifier_Flags;
    show_ui := true;
    show_global_settings_ui := false;
    show_help_ui := false;
    show_console_ui := false;

    camera_rotation_axis : Camera_Rotation_Axis;

    camera : Camera;
    console : Console;
    entities : [..]*Entity;

    vertex_label_style : VertexLabelStyle;

    keymap : Keymap;
    keymap_keydown : Keymap;

    closing_application := false; // Set this to true to close the application
}

Modifier_Flags :: struct {
    shift_pressed   := false;
    control_pressed := false;
    alt_pressed     := false;
}

V2_ZERO :: Vector2.{0, 0};

current_window_aspect_ratio_width_over_height :: () -> float {
    return cast(float) app.current_window_width / cast(float) app.current_window_height;
}

main :: () {

    SDL_Init(SDL_INIT_VIDEO);

    app.window = SDL_CreateWindow(tprint("View v%", VIEW_VERSION_STRING).data,
                                  SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                                  app.INITIAL_WINDOW_WIDTH, app.INITIAL_WINDOW_HEIGHT,
                                  SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    // Check that the window was successfully created
    if app.window == null {
        // In the case that the window could not be made...
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    // print("%\n", to_string(ImGui.GetVersion()));

    // @FIXME If I don't explicitly set attributes here gl_get_version() returns a different result
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 6);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(app.window);
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

    // Prepare VAO
    {
        glGenVertexArrays(1, *app.polyline_vao);
        glGenVertexArrays(1, *app.mesh_vao);
    }

    triad := make_axes_triad(10);

    init_font();
    init_commands();
    init_keymap();

    ImGui.CreateContext();
    ImGui_ImplSdl_Init(app.window);

    if false {
        ImGui.SetWindowPos(pos=*V2_ZERO);
    }

    // Setup style
    // ImGui.StyleColorsClassic();
    // ImGui.StyleColorsLight();
    ImGui.StyleColorsDark();

    // cursor_text := alloc_string(16);
    // defer free(cursor_text);
    // cursor_text.data[cursor_text.count] = 0;
    // cursor_text:="hello";

    {
        args := get_command_line_arguments();
        defer array_free(args);
        for 1..args.count-1 {
            load_entity_from_file(args[it]);
        }
    }

    // Main loop
    while !app.closing_application {
        // You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
        // - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
        // - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
        // Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
        event: SDL_Event;
        while SDL_PollEvent(*event) {
            ImGui_ImplSdl_ProcessEvent(*event);

            app.modifier_flags.shift_pressed   = xx (SDL_GetModState() & KMOD_SHIFT);
            app.modifier_flags.control_pressed = xx (SDL_GetModState() & KMOD_CTRL);
            app.modifier_flags.alt_pressed     = xx (SDL_GetModState() & KMOD_ALT);

            if event.type == {
                case SDL_QUIT; {
                    app.closing_application = true;
                }
                case SDL_WINDOWEVENT;
                    if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {

                        width_scale  := cast(float) event.window.data1 / app.current_window_width;
                        height_scale := cast(float) event.window.data2 / app.current_window_height;

                        camera_delta_rl   := (1. -  width_scale) * (app.camera.right - app.camera.left) / 2;
                        camera_delta_tb   := (1. - height_scale) * (app.camera.top   - app.camera.bottom) / 2;
                        app.camera.right  -= camera_delta_rl;
                        app.camera.left   += camera_delta_rl;
                        app.camera.top    -= camera_delta_tb;
                        app.camera.bottom += camera_delta_tb;

                        app.current_window_width  = event.window.data1;
                        app.current_window_height = event.window.data2;
                    }
                case SDL_KEYDOWN; {
                    if io().WantCaptureKeyboard break;

                    for app.keymap_keydown.mappings {
                        if to_sdl_keycode(it.key_code) == event.key.keysym.sym {
                            if app.modifier_flags.shift_pressed   == it.modifier_flags.shift_pressed   &&
                               app.modifier_flags.control_pressed == it.modifier_flags.control_pressed &&
                               app.modifier_flags.alt_pressed     == it.modifier_flags.alt_pressed {
                                app.keymap_keydown.procs[it.proc_info_index].proc();
                                break;
                            }
                        }
                    }
                }
                case SDL_KEYUP; {
                    if io().WantCaptureKeyboard break;

                    for app.keymap.mappings {
                        if to_sdl_keycode(it.key_code) == event.key.keysym.sym {
                            if app.modifier_flags.shift_pressed   == it.modifier_flags.shift_pressed   &&
                               app.modifier_flags.control_pressed == it.modifier_flags.control_pressed &&
                               app.modifier_flags.alt_pressed     == it.modifier_flags.alt_pressed {
                                app.keymap.procs[it.proc_info_index].proc();
                                break;
                            }
                        }
                    }
                }
                case SDL_DROPFILE; {
                    // @Leak @Cleanup event.drop.file should be free'd using SDL_free
                    dropped := to_string(event.drop.file);
                    load_entity_from_file(dropped);
                }
            }
        }

        ImGui.GetStyle().WindowRounding = 0;
        ImGui_ImplSdl_NewFrame(app.window);

        if app.show_ui {
            show_global_settings_ui(*triad);
            show_scene_ui();
            show_camera_controls();
            show_help_ui();
            console_draw();
        }

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
        glClearColor(app.clear_color.x, app.clear_color.y, app.clear_color.z, app.clear_color.w);
        glEnable(GL_DEPTH_TEST);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);

        // Update after clearing viewport so we can debug visualise stuff
        // @Cleanup: use delta_time argument?
        update_camera(1);

        label_limit : int = 2000;
        Reserve_Labels :: (count : int) #expand { `label_limit -= count; }

        for entity : app.entities {
            if !entity.visible continue;

            if entity.type == {
                case .POLYLINE_SOUP2;

                    soup := cast(*Polyline_Soup2_Entity) entity;
                    render_mesh(soup.mesh, app.vertex_label_style, entity.flash_wave_dt);
                    for polyline : soup.shape.polylines {
                        Reserve_Labels(polyline.points.count);
                        if label_limit >= 0 {
                            render_vertex_labels(polyline.points, app.vertex_label_style);
                        }
                    }

                case .POLYLINE_SOUP3;

                    soup := cast(*Polyline_Soup2_Entity) entity;
                    render_mesh(soup.mesh, app.vertex_label_style, entity.flash_wave_dt);
                    for polyline : soup.shape.polylines {
                        Reserve_Labels(polyline.points.count);
                        if label_limit >= 0 {
                            render_vertex_labels(polyline.points, app.vertex_label_style);
                        }
                    }

                case .POLYGON_SOUP;

                    soup := cast(*Polygon_Soup_Entity) entity;
                    render_mesh(soup.mesh, app.vertex_label_style, entity.flash_wave_dt);
                    for polygon : soup.shape.polygons {
                        Reserve_Labels(point_count(polygon));
                        if label_limit >= 0 {
                            render_vertex_labels(polygon.outer_ring.points, app.vertex_label_style);
                            for inner_ring : polygon.inner_rings {
                                render_vertex_labels(inner_ring.points, app.vertex_label_style);
                            }
                        }
                    }

                case .MESH;

                    mesh := cast(*Mesh_Entity) entity;
                    render_mesh(mesh.mesh, app.vertex_label_style, entity.flash_wave_dt);
                    // @Cleanup so the transform is also available for text rendering
                    Reserve_Labels(mesh.mesh.positions.count);
                    if label_limit >= 0 {
                        render_vertex_labels(mesh.mesh.positions, app.vertex_label_style);
                    }
            }
        }

        if triad.visible {
            render_mesh(triad.origin, .{point_size=0, line_width=1});
            render_mesh(triad.x_axis, .{point_size=0, line_width=1});
            render_mesh(triad.y_axis, .{point_size=0, line_width=1});
            render_mesh(triad.z_axis, .{point_size=0, line_width=1});
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
            render_text_quad(app.text_shader,
                             text,
                             // make_vector2(25.0, WINDOW_HEIGHT - FONT_SIZE * scale),
                             make_vector2(io().MousePos.x, app.current_window_height - io().MousePos.y),
                             scale,
                             make_vector4(1., 1., 1., 1));
        }

        SDL_GL_SwapWindow(app.window);

        reset_temporary_storage();
    }

    // Cleanup
    ImGui_ImplSdl_Shutdown();
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(app.window);
    SDL_Quit();
}

#import "Basic";
#import "File";
#import "String";
#import "Reflection";
#import "Math";
#import "SDL";
#import "ImGui_";
#load "modules/ImGui_/examples/imgui_sdl_gl.jai";

geom :: #import "geometry";
#load "io_obj.jai";
#load "io_wkt.jai";
#load "shaders.jai";
#load "font.jai";
#load "carpet.jai";
#load "camera.jai";
#load "console.jai";
#load "entities.jai";
#load "mesh_utils.jai";
#load "ui.jai";
#load "keymap.jai";
//#load "commands.jai"; // @CompilerBug loading here triggers incorrect (?) compilation error

VertexLabelStyle :: struct {
    show_position := false;
    show_index := false;

    point_size : int = 0; // 0, 2, 4, 6
    line_width : int = 1; // 1, 1, 2, 3
}

#scope_file

load_entity_from_file :: (filename : string) {
    skip := false;
    for app.entities {
        mesh := get_mesh(it);
        if mesh && mesh.fully_pathed_filename == filename {
            skip = true;
            break;
        }
    }
    if skip {
        log("Skipped file: '%' (already loaded)\n", filename);
        return;
    }

    // @Incomplete: support polygon types using wkt format and improve reporting here
    mesh := load_obj(filename);
    if !mesh.positions.count {
        log("Skipped file: '%'\n", filename);
        return;
    }

    if #complete mesh.geometry_format == {
        case .LINES;
            bbox := geom.bounding_box(mesh);
            if diagonal(bbox).z == 0 {
                shape, ok := to_Polyline_Soup2(mesh);
                assert(ok);

                entity := New(Polyline_Soup2_Entity);
                entity.mesh = mesh;
                entity.shape = shape;
                array_add(*app.entities, entity);

                log("Loaded 2d polyline soup file: '%'\n", filename);
            } else {
                shape, ok := to_Polyline_Soup3(mesh);
                assert(ok);

                entity := New(Polyline_Soup3_Entity);
                entity.mesh = mesh;
                entity.shape = shape;
                array_add(*app.entities, entity);

                log("Loaded 3d polyline soup file: '%'\n", filename);
            }

        case .TRIANGLES;
            entity := New(Mesh_Entity);
            entity.mesh = mesh;
            array_add(*app.entities, entity);

            log("Loaded triangle mesh file: '%'\n", filename);

        case .POINTS; #through;
        case .UNKNOWN; #through;
        case;
            log("Skipped file: '%' (unsupported geometry type %)\n", filename, mesh.geometry_format);
            deinit(*mesh);
    }
}

render_mesh :: (mesh : Mesh, style : VertexLabelStyle, flash_dt : float = 0) {
    using app;

    assert(!mesh.is_dirty);

    glUseProgram(mesh_shader);

    assert(camera.projection_type == .ORTHOGRAPHIC);

    {
        model_loc := glGetUniformLocation(mesh_shader, "world_from_model");
        glUniformMatrix4fv(model_loc, 1, true, *mesh.world_from_model._11);
        print_errors();
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
        glUniform1i(mode_loc, xx mesh.display_mode);
    }

    {
        loc := glGetUniformLocation(mesh_shader, "wave");
        wave := ifx flash_dt == 0 then -1 else cos(5 * flash_dt);
        glUniform1f(loc, wave);
    }

    {
        color_loc := glGetUniformLocation(mesh_shader, "color");
        glUniform4f(color_loc, mesh.color.x, mesh.color.y, mesh.color.z, mesh.color.w);
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
    glBindBuffer(GL_ARRAY_BUFFER, mesh.vbo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mesh.ibo);

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
    glDrawArrays(GL_POINTS, 0, xx mesh.positions.count);
}

render_vertex_labels :: (points : []$T, style : VertexLabelStyle, label_index_offset : int = 0) {
    #assert(T == Vector2 || T == Vector3);
    dim :: #run geom.dimension_of(T);

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

    // @TODO call render_text_quad once with a list of points
    for points {
        text : string;
#if dim == 2 {
        if  style.show_index &&  style.show_position text = tprint("% (% %)", label_index_offset + it_index, it.x, it.y);
        if !style.show_index &&  style.show_position text = tprint("(% %)", it.x, it.y);
} else {
        if style.show_index && style.show_position text = tprint("% (% % %)", label_index_offset + it_index, it.x, it.y, it.z);
        if !style.show_index && style.show_position text = tprint("(% % %)", it.x, it.y, it.z);
}
        if  style.show_index && !style.show_position text = tprint("%", label_index_offset + it_index);
        if !style.show_index && !style.show_position break;

        text_w := get_text_width_in_pixels(text, 1.0);
        scale := 0.3;

        // [-1, 1]x[-1,1] -> [0, current_window_width]x[0, current_window_height]
#if dim == 2 {
        text_position_px := projection_from_model * make_vector4(it.x, it.y, 0, 1.);
} else {
        text_position_px := projection_from_model * make_vector4(it.x, it.y, it.z, 1.);
}
        text_position_px.x = cast(float)app.current_window_width * (text_position_px.x + 1) / 2;
        text_position_px.y = cast(float)app.current_window_height * (text_position_px.y + 1) / 2;

        render_text_quad(app.text_shader, text, text_position_px.xy, scale, make_vector4(1., 1., 1., 1));
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

to_sdl_keycode :: (key_code : u32) -> SDL_Keycode {
    if key_code >= 32 return xx key_code;

    special_key_code : Special_Key_Code = xx key_code;
    if #complete special_key_code == {
        case Special_Key_Code.ESCAPE; return SDLK_ESCAPE;
    }
    return SDLK_UNKNOWN;
}

#import "Compiler";
#run compiler_set_type_info_flags(GL_Procedures, .NO_SIZE_COMPLAINT);
#run compiler_set_type_info_flags(ImGui, .NO_SIZE_COMPLAINT);