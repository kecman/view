#load "app.jai";

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

    // #assert(OS == .LINUX);
    // wmInfo: SDL_SysWMinfo ;
    // SDL_VERSION(*wmInfo.version);
    // SDL_GetWindowWMInfo(app.window, *wmInfo);
    // printv(#code wmInfo);// "%\n")io.ImeWindowHandle = wmInfo.info.win.window;
    // x11_window := wmInfo.info.x11.window;
    // Simp.simp_init(x11_window, app.current_window_width, app.current_window_height, app.current_window_width, app.current_window_height);

    init_camera();

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

    {
        vert :: #run read_entire_file("src/shaders/text.vert");
        frag :: #run read_entire_file("src/shaders/text.frag");
        app.text_program = get_shader_program(vert, frag);
    }

    {
        vert :: #run read_entire_file("src/shaders/mesh.vert");
        frag :: #run read_entire_file("src/shaders/mesh.frag");
        app.mesh_program = get_shader_program(vert, frag);
        glGenVertexArrays(1, *app.mesh_vao);
    }

    {
        vert :: #run read_entire_file("src/shaders/normals.vert");
        geom :: #run read_entire_file("src/shaders/normals.geom");
        frag :: #run read_entire_file("src/shaders/normals.frag");
        app.normals_program = get_shader_program(vert, frag, geom);
        glGenVertexArrays(1, *app.normals_vao);
    }

    {
        vert :: #run read_entire_file("src/shaders/aabb.vert");
        frag :: #run read_entire_file("src/shaders/aabb.frag");
        app.aabb_program = get_shader_program(vert, frag);
        glGenVertexArrays(1, *app.aabb_vao);
    }

    {
        vert :: #run read_entire_file("src/shaders/background.vert");
        frag :: #run read_entire_file("src/shaders/background.frag");
        app.background_program = get_shader_program(vert, frag);
        glGenVertexArrays(1, *app.background_vao);
    }

    TRIAD_AXIS_LENGTH :: 1;
    triad := make_axes_triad(TRIAD_AXIS_LENGTH);

    init_font();
    init_commands();
    init_keymap();

    ImGui.CreateContext();
    ImGui_ImplSdl_Init(app.window);
    ImGui.StyleColorsDark();

    load_from_command_line();

    // Main loop
    while !app.closing_application {
        handle_events();

        ImGui.GetStyle().WindowRounding = 0;
        ImGui_ImplSdl_NewFrame(app.window);

        if app.show_ui {
            show_global_settings_ui(*triad);
            show_item_list_ui();
            show_camera_controls();
            show_help_ui();
            console_draw();
            // inspect("Debug", *app.camera, true);
        }

        #if false {
            debug_print_active_uniforms(app.text_shader);
            debug_print_active_uniforms(app.mesh_shader);
        }

        glViewport(0, 0, xx io().DisplaySize.x, xx io().DisplaySize.y); // @TODO Is DisplaySize updated with window resizing? Use current_window_height/width here?
        glEnable(GL_DEPTH_TEST);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);

        render_background();

        // Update after clearing viewport so we can debug visualise stuff
        // @Cleanup: use delta_time argument?
        update_camera(1);

        render_entities();

        if app.user_selection.is_visible {
            do_selection_mode();
        }

        if triad.visible {
            render_axes_triad(*triad);
        }

        ImGui.Render();

        SDL_GL_SwapWindow(app.window);

        reset_temporary_storage();
    }

    ImGui_ImplSdl_Shutdown();
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(app.window);
    SDL_Quit();
}

load_from_command_line :: () {
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

handle_events :: () {
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
