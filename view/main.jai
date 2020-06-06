#import "Basic";
#import "File";
#import "String";

#import "Math";

geom :: #import "Geom";

#load "vendor/imgui_sdl_gl.jai";
#load "shaders.jai";
#load "font.jai";
#load "camera.jai";

//#import "Debug";

INITIAL_WINDOW_WIDTH  : s32 : 1280;
INITIAL_WINDOW_HEIGHT : s32 : 720;

current_window_width := INITIAL_WINDOW_WIDTH;
current_window_height := INITIAL_WINDOW_HEIGHT;

text_shader : GLuint;
text_vao : GLuint;
text_vbo : GLuint;

polyline_shader : GLuint;
polyline_vao : GLuint;
polyline_vbo : GLuint;

render_polyline :: (shader_program: GLuint, polyline : *geom.Polyline2) {
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

MouseState :: struct {
    position_px : Vector2;
    velocity_px : Vector2;
    wheel :       float;
    left_down :   bool;
    right_down :  bool;
    middle_down : bool;
}

main :: () {

    SDL_Init(SDL_INIT_VIDEO);

    window := SDL_CreateWindow("View", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

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

    init_camera();

    // OGL Options
    {
    }

    // Setup text shader
    {
        projection := orthographic_projection_matrix(0.0, xx current_window_width, 0.0, xx current_window_height, -1.0, 1.0);
        mvp := projection;

        vert := read_entire_file("data/shaders/text.vert");
        frag := read_entire_file("data/shaders/text.frag");
        defer free(vert);
        defer free(frag);

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

    // Setup line shader
    {
        vert := read_entire_file("data/shaders/polyline.vert");
        frag := read_entire_file("data/shaders/polyline.frag");
        defer free(vert);
        defer free(frag);

        polyline_shader = get_shader_program(vert, frag);

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

    polyline := geom.polyline_make_box();

    {
        // This should be dynamic, depending on the camera etc
        world_from_model := matrix4_identity();
        view_from_world := make_look_at_matrix(*camera);
        projection_from_view := make_orthographic_projection_matrix(*camera);

        projection_from_model := projection_from_view * view_from_world * world_from_model;


        glUseProgram(polyline_shader);
        mvp_loc := glGetUniformLocation(polyline_shader, "mvp");
        glUniformMatrix4fv(mvp_loc, 1, GL_TRUE, *projection_from_model._11);
        // print("exit(0) at %:%\n", #location().fully_pathed_filename, #location().line_number); exit(0);
    }


    init_font();

    ImGui.CreateContext();
    // Setup ImGui binding
    ImGui_ImplSdl_Init(window);

    // Setup style
    ImGui.StyleColorsClassic();
    //ImGui.StyleColorsLight();

    io := ImGui.GetIO();

    show_demo_window := false;
    // clear_color := make_vector4(0.45, 0.55, 0.60, 1.00);
    clear_color := make_vector4(87./256, 194./256, 248./256, 1.00);

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
            ImGui.ColorEdit3("clear color", clear_color.component);
            if ImGui.Button("Demo Window", size=*make_vector2(0,0)) show_demo_window ^= true;
            ImGui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.Framerate, io.Framerate);

            w, h : s32;
            SDL_GetWindowSize(window, *w, *h);
            ImGui.Text(sprint("Window size %1x%2", w, h));
            if ImGui.Button("Reset Window Size", size=*make_vector2(0,0)) SDL_SetWindowSize(window, INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT);

            if ImGui.Button("Reset to bounds", size=*make_vector2(0,0)) {
                bounds := geom.bounding_box(*polyline);
                geom.offset(*bounds, 0.05 * geom.extents(*bounds));
                update_to_fit_on_screen(*camera, *bounds);
            }
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

        mouse_state : MouseState;
        mouse_state.position_px = make_vector2(io.MousePos.x, io.MousePos.y);
        mouse_state.velocity_px = make_vector2(io.MouseDelta.x, io.MouseDelta.y);
        mouse_state.wheel = io.MouseWheel;
        mouse_state.left_down = io.MouseDown[0];
        mouse_state.right_down = io.MouseDown[1];
        mouse_state.middle_down = io.MouseDown[2];

        update_camera(*camera, 1, *mouse_state);

        {
            world_from_model := matrix4_identity();
            view_from_world := make_look_at_matrix(*camera);
            projection_from_view := make_orthographic_projection_matrix(*camera);
            projection_from_model := projection_from_view * view_from_world * world_from_model;

            // model_point := make_vector4(1, 0, 0, 1);
            // world_point := world_from_model * model_point;
            // view_point := view_from_world * world_point;
            // projection_point := projection_from_view * view_point; // clip_point??
            // ndc_point := make_vector4(projection_point.x / projection_point.w,
            //                           projection_point.y / projection_point.w,
            //                           projection_point.z / projection_point.w,
            //                           1);
            // print("model=%\nworld=%\nview=%\nprojection=%\nndc=%\n", model_point, world_point, view_point, projection_point, ndc_point);

            glUseProgram(polyline_shader);
            mvp_loc := glGetUniformLocation(polyline_shader, "mvp");
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
            debug_print_active_uniforms(polyline_shader);

            // glUseProgram(polyline_shader);
            // mvp_loc := glGetUniformLocation(polyline_shader, "mvp");
            // glUniformMatrix4fv(mvp_loc, 1, GL_TRUE, *projection_from_local._11);
        }

        // Rendering
        glViewport(0, 0, xx io.DisplaySize.x, xx io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
        render_polyline(polyline_shader, *polyline);
        ImGui.Render();

        {
            glEnable(GL_BLEND);
            defer glDisable(GL_BLEND);
            glDisable(GL_CULL_FACE); // LTB---will f-you up with triangles. if only 2d stuff just leave blending on
            defer glEnable(GL_CULL_FACE);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            text := "Hello";
            text_w := get_text_width_in_pixels(text, 1.0);
            scale := 0.5;
            render_text_quad(text_shader,
                             text,
                             // make_vector2(25.0, WINDOW_HEIGHT - FONT_SIZE * scale),
                             make_vector2(io.MousePos.x, current_window_height - io.MousePos.y),
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

debug_print_active_uniforms :: (shader : GLuint) {
    max_length: GLint;
    glGetProgramiv(polyline_shader, GL_ACTIVE_UNIFORM_MAX_LENGTH, *max_length);
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
