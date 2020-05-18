#import "Basic";
#import "Compiler";
#import "File";
#load "vendor/imgui_sdl_gl.jai";
#load "shaders.jai";
#load "font.jai";

//#import "Debug";

WINDOW_WIDTH  :: 1280;
WINDOW_HEIGHT :: 720;

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

Polyline2 :: struct {
    Point :: Vector2;
    points : [..] Point;
    buffer_id : GLuint;
    is_dirty := true;
}

buffer_polyline :: (using polyline : *Polyline2) {
    if is_dirty {
        if !buffer_id {
            glGenBuffers(1, *buffer_id);
        }
        glBindBuffer(GL_ARRAY_BUFFER, buffer_id);
        glBufferData(GL_ARRAY_BUFFER, size_of(type_of(points[0])) * points.count, points.data, GL_STATIC_DRAW);
        is_dirty = false;
    }
}

render_polyline :: (shader_program: GLuint, polyline : *Polyline2) {
    // for polyline.points print("% %\n", it_index, it);

    glUseProgram(polyline_shader);
    // position := game.camera_position;
    // glUniform3f(uniloc(shader, "camera.position"), position.x, position.y, position.z);

    assert(polyline.is_dirty == false);
    glBindBuffer(GL_ARRAY_BUFFER, polyline.buffer_id);

    glBindVertexArray(polyline_vao);
    
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, false, size_of(polyline.Point), null);
    // glVertexAttrib4f(ATTRIB_COLOR, 1.0, 1.0, 1.0, 1.0);
    glDrawArrays(GL_LINE_STRIP, 0, xx polyline.points.count);
    
    glDisableVertexAttribArray(0);
}

main :: () {

    SDL_Init(SDL_INIT_VIDEO);

    window := SDL_CreateWindow("ImGui SDL2+OpenGL example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, xx WINDOW_WIDTH, xx WINDOW_HEIGHT, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    // Check that the window was successfully created
    if window == null {
        // In the case that the window could not be made...
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    // print("%\n", to_string(ImGui.GetVersion()));

    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(window);
    if !gl_context {
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }

    gl_load(*gl, SDL_GL_GetProcAddress);

    gl_enable_debug_output(break_on_error=true);

    // OGL Options
    {
    }

    // Setup text shader
    {
        projection := orthographic_projection_matrix(0.0, xx WINDOW_WIDTH, 0.0, xx WINDOW_HEIGHT, -1.0, 1.0);

        vert := read_entire_file("data/shaders/text.vert");
        frag := read_entire_file("data/shaders/text.frag");
        defer free(vert);
        defer free(frag);

        text_shader = get_shader_program(vert, frag);

        glUseProgram(text_shader);
        projection_loc := glGetUniformLocation(text_shader, "projection");
        glUniformMatrix4fv(projection_loc, 1, GL_TRUE, *projection._11);
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

    // Setup line shader
    {
        projection := orthographic_projection_matrix(0.0, xx WINDOW_WIDTH, 0.0, xx WINDOW_HEIGHT, -1.0, 1.0);

        vert := read_entire_file("data/shaders/polyline.vert");
        frag := read_entire_file("data/shaders/polyline.frag");
        defer free(vert);
        defer free(frag);

        polyline_shader = get_shader_program(vert, frag);

        glUseProgram(polyline_shader);
        projection_loc := glGetUniformLocation(polyline_shader, "projection");
        glUniformMatrix4fv(projection_loc, 1, GL_TRUE, *projection._11);
    }

    // Prepare VAO for lines
    {
        glGenVertexArrays(1, *polyline_vao);
        glGenBuffers(1, *polyline_vbo);
        glBindVertexArray(polyline_vao);
        glBindBuffer(GL_ARRAY_BUFFER, polyline_vbo);
        glBufferData(GL_ARRAY_BUFFER, size_of(GLfloat) * 6 * 4, null, GL_DYNAMIC_DRAW);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, 4 * size_of(GLfloat), xx 0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
    }

    polyline : Polyline2;
    array_add(*polyline.points, make_vector2(-100, -100));
    array_add(*polyline.points, make_vector2( -.5, -.5));
    array_add(*polyline.points, make_vector2(  .5,  .5));
    array_add(*polyline.points, make_vector2( 100,  100));
    buffer_polyline(*polyline);


    init_font();

    ImGui.CreateContext();
    // Setup ImGui binding
    ImGui_ImplSdl_Init(window);

    // Setup style
    ImGui.StyleColorsClassic();
    //ImGui.StyleColorsLight();

    io := ImGui.GetIO();

    show_demo_window := false;
    clear_color := make_vector4(0.45, 0.55, 0.60, 1.00);

    f :float = 0.0;

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
                case SDL_QUIT;
                    done = true;
                case SDL_KEYUP;
                    if event.key.keysym.sym == SDLK_ESCAPE done = true;
            }
        }
        ImGui_ImplSdl_NewFrame(window);

        {
            ImGui.Text("Hello, world!");
            ImGui.SliderFloat("float", *f, 0.0, 1.0, "%.3f");
            ImGui.ColorEdit3("clear color", clear_color.component);
            if ImGui.Button("Demo Window", size=*make_vector2(0,0)) show_demo_window ^= true;
            ImGui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.Framerate, io.Framerate);
        }

        if show_demo_window {
            ImGui.SetNextWindowPos(*make_vector2(650, 20), ImGui.Cond.FirstUseEver, *make_vector2(0,0));
            ImGui.ShowDemoWindow(*show_demo_window);
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

        // io := ImGui.GetIO(); // Error: Variable 'io' is used before its declaration.
        // print("%\n", << io);


        // Rendering
        glViewport(0, 0, xx io.DisplaySize.x, xx io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui.Render();


        render_polyline(polyline_shader, *polyline);

        {
            glEnable(GL_BLEND);
            defer glDisable(GL_BLEND);
            glDisable(GL_CULL_FACE); // LTB---will f-you up with triangles. if only 2d stuff just leave blending on
            defer glEnable(GL_CULL_FACE);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            text := "HIH";
            text_w := get_text_width_in_pixels(text, 1.0);
            scale := 0.5;
            render_text_quad(text_shader,
                             text,
                             // make_vector2(25.0, WINDOW_HEIGHT - FONT_SIZE * scale),
                             make_vector2(io.MousePos.x, WINDOW_HEIGHT - io.MousePos.y),
                             scale,
                             make_vector4(0.5, 0.8, 0.2, 1));
        }

        SDL_GL_SwapWindow(window);
    }

    // Cleanup
    ImGui_ImplSdl_Shutdown();
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();
}


build :: () {

    build_options := get_build_options();
    // build_options.output_type = Build_Output_Type.NO_OUTPUT;
    build_options.lazy_foreign_function_lookups = true;
    print("%\n\n", build_options);

}

#run build();