#import "Basic";
#import "File";
#import "String";
#import "Math";

geom :: #import "geometry";
#import "BoostPolygon";

#load "io.jai";
#load "vendor/imgui_sdl_gl.jai";
#load "shaders.jai";
#load "font.jai";
#load "camera.jai";
#load "console.jai";
//#load "commands.jai"; // @CompilerBug? loading this here and console.jai causes:Error: Redeclaration of variable 'command_list'. but I think this should work? Hmmm

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

show_ui := true;    // Wish we could declare static variables inside functions.

// @Cleanup :OnlyRenderMeshType: This should represent the calculator memory, it should be an array of a base type with an enum that
//  identifies the type stored in the memory slot, that type will have ui render info (imgui widgets) and graphical render info (mesh)
geometries : [..] *geom.Renderable_Geometry;

// @TODO move this into the polyine struct
VertexLabelStyle :: struct {
    show_position := false;
    show_index := false;

    point_size : int = 4; // 0, 2, 4, 6
    line_width : int = 2; // 1, 1, 2, 3
}

// @Cleanup :OnlyRenderMeshType:
render_polyline :: (polyline : *geom.Renderable_Polyline2, style : *VertexLabelStyle) {

    if !polyline || !polyline.visible {
        return;
    }

    assert(polyline.is_dirty == false);

    glUseProgram(polyline_shader);

    line_color_loc := glGetUniformLocation(polyline_shader, "line_color");
    glUniform4f(line_color_loc, polyline.line_color.x, polyline.line_color.y, polyline.line_color.z, polyline.line_color.w);
    point_size_loc := glGetUniformLocation(polyline_shader, "point_size");
    glUniform1f(point_size_loc, xx style.point_size);

    glBindVertexArray(polyline_vao);
    glBindBuffer(GL_ARRAY_BUFFER, polyline.vbo);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, false, size_of(polyline.Point), null);

    last_line_width: float;
    glGetFloatv(GL_LINE_WIDTH, xx *last_line_width);
    defer glLineWidth(last_line_width);
    glLineWidth(xx style.line_width); // 1, 2, 3... See also glEnable(GL_LINE_SMOOTH);

    glDrawArrays(GL_LINE_STRIP, 0, xx polyline.points.count);
    glEnable(GL_PROGRAM_POINT_SIZE);
    glDrawArrays(GL_POINTS, 0, xx polyline.points.count);

    glDisableVertexAttribArray(0);
}

render_polyline_soup :: (soup : *geom.Renderable_Polyline_Soup2, style : *VertexLabelStyle) {

    if !soup || !soup.visible {
        return;
    }

    assert(soup.is_dirty == false);

    glUseProgram(polyline_shader);

    line_color_loc := glGetUniformLocation(polyline_shader, "line_color");
    glUniform4f(line_color_loc, soup.line_color.x, soup.line_color.y, soup.line_color.z, soup.line_color.w);
    point_size_loc := glGetUniformLocation(polyline_shader, "point_size");
    glUniform1f(point_size_loc, xx style.point_size);

    glBindVertexArray(polyline_vao);
    glBindBuffer(GL_ARRAY_BUFFER, soup.vbo);

    last_line_width: float;
    glGetFloatv(GL_LINE_WIDTH, xx *last_line_width);
    defer glLineWidth(last_line_width);
    glLineWidth(xx style.line_width); // 1, 2, 3... See also glEnable(GL_LINE_SMOOTH);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, false, size_of(soup.Point), null);

    offset := 0;
    for polyline : soup.polylines {
        glDrawArrays(GL_LINE_STRIP, xx offset, xx polyline.points.count);
        glEnable(GL_PROGRAM_POINT_SIZE);
        glDrawArrays(GL_POINTS, xx offset, xx polyline.points.count);
        offset += polyline.points.count;
    }

    glDisableVertexAttribArray(0);
}


render_vertex_labels :: (points : []Vector2, style : *VertexLabelStyle, label_index_offset : int = 0) {
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

        vert :: #run read_entire_file("source/shaders/text.vert");
        frag :: #run read_entire_file("source/shaders/text.frag");
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
        vert :: #run read_entire_file("source/shaders/polyline.vert");
        frag :: #run read_entire_file("source/shaders/polyline.frag");
        polyline_shader = get_shader_program(vert, frag);
    }

    // Prepare VAO for lines
    {
        glGenVertexArrays(1, *polyline_vao);
    }

    /*
    test_soup := New(geom.Renderable_Polyline_Soup2);
    defer free(test_soup);
    {
        using test_soup.geometry;
        array_add(*polylines, geom.to_polyline(*geom.make_axis_box(make_vector2(-10, -10), make_vector2(10, 10))));
        array_add(*polylines, geom.to_polyline(*geom.make_axis_box(make_vector2(-50, -50), make_vector2(50, 50))));
    }
    geom.buffer_polyline_soup(test_soup);
    array_add(*geometries, test_soup);
    */

    vertex_label_style : VertexLabelStyle;

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


            cursor_text := alloc_string(16);
            defer free(cursor_text);
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
                case SDL_QUIT;
                    done = true;
                case SDL_KEYUP;
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

                case SDL_DROPFILE;
                    dropped := to_string(event.drop.file);

                    skip := false;
                    for geometries {
                        if it.filename == dropped {
                            skip = true;
                            break;
                        }
                    }

                    if skip {
                        print("Skipped file: '%' (already loaded)\n", dropped);
                    } else {
                        obj := load_obj(dropped);
                        print("Loaded file: '%'\n", dropped);

                        soup2, success := to_Polyline_Soup2(obj);
                        defer array_free(soup2.polylines);

                        if !success {
                            print("Skipped file: '%' (only 2D polylines with constant z are supported)\n", dropped);
                            continue;
                        }

                        if soup2.polylines.count == {
                            case 0; {
                                continue;
                            }

                            case 1; {
                                renderable := New(geom.Renderable_Polyline2);
                                renderable.filename = dropped;
                                array_copy(*renderable.geometry.points, soup2.polylines[0].points);
                                geom.buffer_polyline(renderable);
                                array_add(*geometries, renderable);
                            }

                            case; {
                                renderable := New(geom.Renderable_Polyline_Soup2);
                                renderable.filename = dropped;
                                array_copy(*renderable.geometry.polylines, soup2.polylines);
                                for soup2.polylines {
                                    array_copy(*renderable.geometry.polylines[it_index].points, soup2.polylines[it_index].points);
                                }
                                geom.buffer_polyline_soup(renderable);
                                array_add(*geometries, renderable);
                            }
                        }

                        fit_on_screen();
                    }
            }
        }
        ImGui_ImplSdl_NewFrame(window);

        {
            ImGui.SetNextWindowPos(pos=*make_vector2(10, 10), pivot=*make_vector2(0,0));
            ImGui.Begin("", *show_ui, ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
            ImGui.ColorEdit3("Background Color", clear_color.component, ImGui.ColorEditFlags.NoInputs);

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

            for geometries {
                if #complete it.type == {
                    // @Cleanup duplication
                    case geom.Renderable_Geometry_Type.POLYLINE2;
                        p := cast(*geom.Renderable_Polyline2) it;
                        ImGui.Checkbox(imgui_label(path_filename(it.filename), xx it), *it.visible);
                        ImGui.SameLine();
                        ImGui.ColorEdit3(imgui_label("", it), p.line_color.component, ImGui.ColorEditFlags.NoInputs);
                        ImGui.SameLine();

                        if ImGui.Button(imgui_label("Remove", it), size=*make_vector2(0, 0)) {
                            glDeleteBuffers(1, *it.vbo);
                            free(it);
                            remove it;
                        }

                    case geom.Renderable_Geometry_Type.POLYLINE_SOUP2;
                        p := cast(*geom.Renderable_Polyline_Soup2) it;
                        ImGui.Checkbox(imgui_label(path_filename(it.filename), xx it), *it.visible);
                        ImGui.SameLine();
                        ImGui.ColorEdit3(imgui_label("", it), p.line_color.component, ImGui.ColorEditFlags.NoInputs);
                        ImGui.SameLine();

                        if ImGui.Button(imgui_label("Remove", it), size=*make_vector2(0, 0)) {
                            glDeleteBuffers(1, *it.vbo);
                            free(it);
                            remove it;
                        }
                }
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
        }

        // Rendering
        glViewport(0, 0, xx imgui_io.DisplaySize.x, xx imgui_io.DisplaySize.y);
        glClearColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w);
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
        for geometries {
            if it.visible {
                if #complete it.type == {
                    case .POLYLINE2;
                        polyline := cast(*geom.Renderable_Polyline2) it;
                        render_polyline(polyline, *vertex_label_style);
                        render_vertex_labels(polyline.points, *vertex_label_style);
                    case .POLYLINE_SOUP2;
                        soup := cast(*geom.Renderable_Polyline_Soup2) it;
                        render_polyline_soup(soup, *vertex_label_style);
                        offset := 0;
                        for polyline : soup.polylines {
                            render_vertex_labels(polyline.points, *vertex_label_style, offset);
                            offset += polyline.points.count;
                        }
                }
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
    for geometries {
        if it.visible {
            if #complete it.type == {
                case .POLYLINE2;
                    shape := cast(*geom.Renderable_Polyline2)it;
                    bounds := geom.bounding_box(shape);
                    geom.expand(*overall_bounds, *bounds);
                case .POLYLINE_SOUP2;
                    shape := cast(*geom.Renderable_Polyline_Soup2)it;
                    bounds := geom.bounding_box(shape);
                    geom.expand(*overall_bounds, *bounds);
            }
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
