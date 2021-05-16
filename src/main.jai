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

    TRIAD_AXIS_LENGTH :: 1;
    triad := make_axes_triad(TRIAD_AXIS_LENGTH);

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
            found, _ := find_entity_with_max_generation_index(args[it]);
            if found {
                if #complete app.settings.duplicate_file_behaviour == {
                    case .OVERWRITE; #through;
                    case .IGNORE;
                        // When loading files from the command line .OVERWRITE and .IGNORE have the same behaviour
                        log("Skipped file: '%' (already loaded)\n", args[it]);
                        break;
                    case .APPEND;
                        entity := load_entity_from_file(args[it]);
                        if entity {
                            entity.generation_index = found.generation_index + 1;
                            array_add(*app.entities, entity);
                        }
                }
            } else {
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
                    found, found_index := find_entity_with_max_generation_index(dropped);
                    if found {
                        if #complete app.settings.duplicate_file_behaviour == {
                            case .IGNORE;

                                log("Skipped file: '%' (already loaded)\n", dropped);

                            case .OVERWRITE;

                                // Only affects the entity with maximum generation index
                                entity := load_entity_from_file(dropped);
                                if entity {
                                    entity.generation_index = found.generation_index;
                                    deinit(found);
                                    app.entities[found_index] = entity;
                                }

                            case .APPEND;
                                entity := load_entity_from_file(dropped);
                                if entity {
                                    entity.generation_index = found.generation_index + 1;
                                    array_add(*app.entities, entity);
                                }
                        }
                    } else {
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

        Render_Entity :: (entity : *Entity) #expand {
            if entity.type == {
                case .POLYLINE_SOUP2;

                    soup := cast(*Polyline_Soup2_Entity) entity;
                    render_mesh(*soup.mesh, *entity.render_info, entity.display_info, app.vertex_label_style);
                    for polyline : soup.shape.polylines {
                        Reserve_Labels(polyline.points.count);
                        if label_limit >= 0 {
                            render_vertex_labels(polyline.points, app.vertex_label_style);
                        }
                    }

                case .POLYLINE_SOUP3;

                    soup := cast(*Polyline_Soup3_Entity) entity;
                    render_mesh(*soup.mesh, *entity.render_info, entity.display_info, app.vertex_label_style);
                    for polyline : soup.shape.polylines {
                        Reserve_Labels(polyline.points.count);
                        if label_limit >= 0 {
                            render_vertex_labels(polyline.points, app.vertex_label_style);
                        }
                    }

                case .POLYGON_SOUP;

                    soup := cast(*Polygon_Soup_Entity) entity;
                    render_mesh(*soup.mesh, *entity.render_info, entity.display_info, app.vertex_label_style);
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
                    render_mesh(*mesh.mesh, *entity.render_info, entity.display_info, app.vertex_label_style);
                    // @Cleanup so the transform is also available for text rendering
                    Reserve_Labels(mesh.mesh.positions.count);
                    if label_limit >= 0 {
                        render_vertex_labels(mesh.mesh.positions, app.vertex_label_style);
                    }
            }
        }

        is_visible_opaque :: (e : *Entity)->bool { return e.display_info.visible && !e.display_info.flash_hovered && get_opacity(<<e) == 1.; }
        is_visible_transparent :: (e : *Entity)->bool { return e.display_info.visible && !e.display_info.flash_hovered && get_opacity(<<e) != 1.; }
        is_visible_flash_hovered :: (e : *Entity)->bool { return e.display_info.visible && e.display_info.flash_hovered; }

        visible_opaque :: #bake_arguments entities_iterator(should_visit = is_visible_opaque);
        visible_transparent :: #bake_arguments entities_iterator(should_visit = is_visible_transparent);
        visible_hovered :: #bake_arguments entities_iterator(should_visit = is_visible_flash_hovered);

        for :visible_opaque      app.entities Render_Entity(it);
        for :visible_transparent app.entities Render_Entity(it);

        // Render the flash hovered item over everything else to make it easy to find
        glClear(GL_DEPTH_BUFFER_BIT);
        for :visible_hovered     app.entities Render_Entity(it);

        if triad.visible {
            using *app.camera;
            old_camera := app.camera;
            defer app.camera = old_camera;

            w, h : float = xx app.current_window_width, xx app.current_window_height;
            s := 80.;
            a := current_window_aspect_ratio_width_over_height();

            near, far = -s, s;
            bottom, top = 0., h;
            left, right = 0., w;
            unit_look_direction := normalize(current_look_direction());
            look_position = make_vector3(0., 0., 0.);
            eye_position = look_position - unit_look_direction;

            offset_vs := make_vector3(s, s, 0.) + make_vector3(WINDOW_BORDER_UI_OFFSET, 0);
            world_from_view := inverse(make_look_at_matrix(app.camera));
            offset_ws := (world_from_view * make_vector4(offset_vs, 0.)).xyz;

            scale := make_scale_matrix4(.8 * make_vector3(s, s, s));
            shift := make_translation_matrix4(offset_ws);
            xform := shift * scale;

            triad.origin.mesh.world_from_model = xform;
            triad.x_axis.mesh.world_from_model = xform;
            triad.y_axis.mesh.world_from_model = xform;
            triad.z_axis.mesh.world_from_model = xform;

            // Always render axes triad in front of everything else
            // glDisable(GL_DEPTH_TEST);
            // defer glEnable(GL_DEPTH_TEST);

            render_mesh(*triad.origin.mesh, *triad.origin.render_info, triad.origin.display_info, .{point_size=0, line_width=1});
            render_mesh(*triad.x_axis.mesh, *triad.x_axis.render_info, triad.x_axis.display_info, .{point_size=0, line_width=1});
            render_mesh(*triad.y_axis.mesh, *triad.y_axis.render_info, triad.y_axis.display_info, .{point_size=0, line_width=1});
            render_mesh(*triad.z_axis.mesh, *triad.z_axis.render_info, triad.z_axis.display_info, .{point_size=0, line_width=1});
        }

        ImGui.Render();

        if app.show_cursor_text && ImGui.IsMousePosValid(*io().MousePos) {
            // Render this last so it appears over everything else
            view_from_clip := inverse(make_orthographic_projection_matrix(app.camera));
            world_from_view := inverse(make_look_at_matrix(app.camera));
            world := world_from_view * view_from_clip * make_vector4(to_ndc(io().MousePos), 0., 0.);
            world.xy += app.camera.eye_position.xy;
            text := tprint("%,%", world.x, world.y);

            debug_text_at_cursor(text);
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

// Returns the entity having the given `fully_pathed_filename` with maximum generation index, or null if no such entity exists
find_entity_with_max_generation_index :: (fully_pathed_filename : string) -> *Entity, int
{
    entity_index := -1;
    max_generation_index := -1;
    max_generation_index_entity : *Entity;
    for app.entities {
        if it.fully_pathed_filename == fully_pathed_filename && it.generation_index > max_generation_index {
            max_generation_index = it.generation_index;
            max_generation_index_entity = it;
            entity_index = it_index;
        }
    }
    return max_generation_index_entity, entity_index;
}

to_sdl_keycode :: (key_code : u32) -> SDL_Keycode {
    if key_code >= 32 return xx key_code;

    special_key_code : Special_Key_Code = xx key_code;
    if #complete special_key_code == {
        case Special_Key_Code.ESCAPE; return SDLK_ESCAPE;
        case Special_Key_Code.ENTER;  return SDLK_RETURN;
        case Special_Key_Code.TAB;    return SDLK_TAB;
        case Special_Key_Code.F1;     return SDLK_F1;
        case Special_Key_Code.F2;     return SDLK_F2;
        case Special_Key_Code.F3;     return SDLK_F3;
        case Special_Key_Code.F4;     return SDLK_F4;
        case Special_Key_Code.F5;     return SDLK_F5;
    }
    return SDLK_UNKNOWN;
}

#load "app.jai";
