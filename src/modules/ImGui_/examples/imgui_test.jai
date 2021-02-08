
#load "imgui_sdl_gl.jai";
//#import "Debug";


main :: () {

    SDL_Init(SDL_INIT_VIDEO);

    window := SDL_CreateWindow("ImGui SDL2+OpenGL example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 720, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    // Check that the window was successfully created
    if window == null {
        // In the case that the window could not be made...
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    print("%\n", to_string(ImGui.GetVersion()));

    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(window);
    if !gl_context {
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }  

    gl_load(*gl, SDL_GL_GetProcAddress);

    ImGui.CreateContext();
    // Setup ImGui binding
    ImGui_ImplSdl_Init(window);

    // Setup style
    ImGui.StyleColorsClassic();
    //ImGui.StyleColorsLight();

    io := ImGui.GetIO();

    show_demo_window := true;
    show_another_window := false;
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
            if event.type == SDL_QUIT done = true;
        }
        ImGui_ImplSdl_NewFrame(window);

        // 1. Show a simple window
        // Tip: if we don't call ImGui::Begin()/ImGui::End() the widgets automatically appears in a window called "Debug".
        {
            ImGui.Text("Hello, world!");                                // Some text (you can use a format string too)
            ImGui.SliderFloat("float", *f, 0.0, 1.0, "%.3f");                   // Edit 1 float as a slider from 0.0f to 1.0f
            ImGui.ColorEdit3("clear color", clear_color.xyz.component);  // Edit 3 floats as a color
            if ImGui.Button("Demo Window", size=*make_vector2(0,0)) show_demo_window ^= true;       // Use buttons to toggle our bools. We could use Checkbox() as well.
            if ImGui.Button("Another Window", size=*make_vector2(0,0)) show_another_window ^= true;
            ImGui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.Framerate, io.Framerate);
        }

        // 2. Show another simple window. In most cases you will use an explicit Begin/End pair to name the window.
        if show_another_window {
            ImGui.Begin("Another Window", *show_another_window);
            ImGui.Text("Hello from another window!");
            ImGui.End();
        }

        // 3. Show the ImGui demo window. Most of the sample code is in ImGui.ShowDemoWindow().
        if show_demo_window {
            ImGui.SetNextWindowPos(*make_vector2(650, 20), ImGui.Cond.FirstUseEver, *make_vector2(0,0)); // Normally user code doesn't need/want to call this because positions are saved in .ini file anyway. Here we just want to make the demo initial state a bit more friendly!
            ImGui.ShowDemoWindow(*show_demo_window);
        }

        using ImGui.MouseCursor;
        if ImGui.GetMouseCursor() == {
            case Arrow;         SDL_SetCursor(cursor_arrow);
            case TextInput;     SDL_SetCursor(cursor_text_input);
            case Move;          SDL_SetCursor(cursor_move);
            case ResizeNS;      SDL_SetCursor(cursor_resize_ns);
            case ResizeEW;      SDL_SetCursor(cursor_resize_ew);
            case ResizeNESW;    SDL_SetCursor(cursor_resize_nesw);
            case ResizeNWSE;    SDL_SetCursor(cursor_resize_nwse);
        }

        // Rendering
        glViewport(0, 0, xx io.DisplaySize.x, xx io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui.Render();
        SDL_GL_SwapWindow(window);
    }

    // Cleanup
    ImGui_ImplSdl_Shutdown();
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

