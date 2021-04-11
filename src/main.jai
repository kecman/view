main :: () {

    SDL_Init(SDL_INIT_VIDEO);

    app.window = SDL_CreateWindow(tprint("Garage v%", VERSION_STRING).data,
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
            if should_load_entity_from_file(args[it]) {
                entity := load_entity_from_file(args[it]);
                if entity {
                    array_add(*app.entities, entity);
                }
            }
        }
        fit_on_screen();
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

                    // @Cleanup move to keymap file
                    if  event.key.keysym.sym == SDLK_F11 {
                        app.fullscreen = !app.fullscreen;
                        flags : u32 = ifx app.fullscreen then cast(u32) 0 else xx SDL_WindowFlags.SDL_WINDOW_FULLSCREEN_DESKTOP;
                        ok := SDL_SetWindowFullscreen(app.window, flags); // @Robustness handle error
                    }

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
                    if should_load_entity_from_file(dropped) {
                        entity := load_entity_from_file(dropped);
                        if entity {
                            array_add(*app.entities, entity);
                        }
                    }

                    if app.settings.fit_to_screen_on_file_drop_event {
                        fit_on_screen();
                    }
                }
            }
        }

        ImGui.GetStyle().WindowRounding = 0;
        ImGui_ImplSdl_NewFrame(app.window);

        if app.show_ui {
            show_global_settings_ui(*triad);
            // show_item_info(); // before show_scene_ui
            show_scene_ui();
            show_camera_controls();
            show_help_ui();
            console_draw();

            // inspect("Debug", *app.camera, true);
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

        label_limit : int = app.label_limit;
        Reserve_Labels :: (count : int) #expand { `label_limit -= count; }

        for entity : app.entities {
            if !entity.display_info.visible continue;

            if entity.type == {
                case .POLYLINE_SOUP2;

                    soup := cast(*Polyline_Soup2_Entity) entity;
                    render_mesh(soup.mesh, entity.display_info, app.vertex_label_style);
                    for polyline : soup.shape.polylines {
                        Reserve_Labels(polyline.points.count);
                        if label_limit >= 0 {
                            render_vertex_labels(polyline.points, app.vertex_label_style);
                        }
                    }

                case .POLYLINE_SOUP3;

                    soup := cast(*Polyline_Soup3_Entity) entity;
                    render_mesh(soup.mesh, entity.display_info, app.vertex_label_style);
                    for polyline : soup.shape.polylines {
                        Reserve_Labels(polyline.points.count);
                        if label_limit >= 0 {
                            render_vertex_labels(polyline.points, app.vertex_label_style);
                        }
                    }

                case .POLYGON_SOUP;

                    soup := cast(*Polygon_Soup_Entity) entity;
                    render_mesh(soup.mesh, entity.display_info, app.vertex_label_style);
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
                    render_mesh(mesh.mesh, entity.display_info, app.vertex_label_style);
                    // @Cleanup so the transform is also available for text rendering
                    Reserve_Labels(mesh.mesh.positions.count);
                    if label_limit >= 0 {
                        render_vertex_labels(mesh.mesh.positions, app.vertex_label_style);
                    }
            }
        }

        triad.origin.display_info.visible = triad.visible;
        triad.x_axis.display_info.visible = triad.visible;
        triad.y_axis.display_info.visible = triad.visible;
        triad.z_axis.display_info.visible = triad.visible;
        if triad.visible {
            render_mesh(triad.origin.mesh, triad.origin.display_info, .{point_size=0, line_width=1});
            render_mesh(triad.x_axis.mesh, triad.x_axis.display_info, .{point_size=0, line_width=1});
            render_mesh(triad.y_axis.mesh, triad.y_axis.display_info, .{point_size=0, line_width=1});
            render_mesh(triad.z_axis.mesh, triad.z_axis.display_info, .{point_size=0, line_width=1});
        }

        ImGui.Render();

        if false { // @Cleanup: remove this
            glEnable(GL_BLEND);
            defer glDisable(GL_BLEND);
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

should_load_entity_from_file :: (filename : string) -> bool
{
    skip := false;
    for app.entities {
        if it.fully_pathed_filename == filename {
            skip = true;
            break;
        }
    }
    if skip {
        log("Skipped file: '%' (already loaded)\n", filename);
    }
    return !skip;
}

to_sdl_keycode :: (key_code : u32) -> SDL_Keycode {
    if key_code >= 32 return xx key_code;

    special_key_code : Special_Key_Code = xx key_code;
    if #complete special_key_code == {
        case Special_Key_Code.ESCAPE; return SDLK_ESCAPE;
    }
    return SDLK_UNKNOWN;
}

#load "app.jai";
