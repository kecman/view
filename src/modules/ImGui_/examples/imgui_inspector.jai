#load "imgui_sdl_gl.jai";

Reflection :: #import "Reflection";


show_inspector := false;    // Wish we could declare static variables inside functions.

inspect :: (name: *u8, t : *$T) {
    
    ImGui.Begin(name, *show_inspector);

    inspect(name, t, type_info(T));

    ImGui.End();
}


inspect :: (name: *u8, data: *void, info:*Type_Info) {
    default_size:ImVec2;

    using Type_Info_Tag;
    if #complete info.type == {
        case INTEGER;
            info_int := cast(*Type_Info_Integer) info;
            ImGui.InputInt(name, data); // @@ Add support for unsigned, and larger int types.
        case FLOAT;
            if info.runtime_size == {
                case 4;
                    //ImGui.DragFloat(name, data, display_format="%.3f");
                    ImGui.InputFloat(name, data, 0.01, 1.0);
                case 8;
                    x : float = xx <<cast(*float64) data;
                    if ImGui.InputFloat(name, *x, 0.01, 1.0) { <<cast(*float64) data = x; };
            }
        case BOOL;
            //ImGui.Checkbox(name, data);
            index : s32 = xx <<cast(*bool)data;
            if ImGui.Combo(name, *index, "false\0true\0\0") { <<cast(*bool)data = xx index; };
        case STRING;
            string_data := Reflection.get_string_data(data, xx info);
            string_count := Reflection.get_string_count(data, xx info);
            
            if string_data ImGui.InputText(name, string_data, xx string_count, ImGui.InputTextFlags.ReadOnly);    // @@ We could allow editing of strings too.
            else ImGui.InputText(name, "(null)", 6, ImGui.InputTextFlags.ReadOnly);

        case POINTER;
            // @@ Open in new window?
            ImGui.Text("pointer");
        case PROCEDURE;
            ImGui.Text("procedure");
        case VOID;
            ImGui.Text("void");
        case CODE;
            ImGui.Text("Code");
        case STRUCT;
            info_struct := cast(*Type_Info_Struct) info;
            if ImGui.TreeNode("%: %", to_string(name), info_struct.name) {
                for member:info_struct.members {
                    inspect(temp_c_string(member.name), data + member.offset_in_bytes, member.type);
                }
                ImGui.TreePop();
            }
        case ARRAY;
            info_array := cast(*Type_Info_Array) info;
            array_count, array_data := Reflection.get_array_count_and_data(data, info_array);
            array_name := to_string(name);
            element_size := info_array.element_type.runtime_size;            
            if ImGui.TreeNode("% (count = %)", array_name, array_count) {
                for 0..array_count-1 {
                    item_name := temp_c_string(tprint("%[%]", array_name, it));
                    inspect(item_name, array_data + it * element_size, info_array.element_type);
                }
                ImGui.TreePop();
            }
        case ANY;
            // @@ Display type and inspect value.
            ImGui.Text("Any!");        
        case ENUM;
            info_enum := cast(*Type_Info_Enum) info;

            if info_enum.enum_type_flags & .Is_Flags {
                // @@ How to handle flags?
            }
            else {
                value := Reflection.get_enum_value(data, info_enum);
                value_name := "";
                for info_enum.names {
                    if value == info_enum.values[it_index]  value_name = it;
                }

                if ImGui.BeginCombo(name, temp_c_string(value_name)) {
                    for info_enum.names {
                        is_selected := value == info_enum.values[it_index];
                        if ImGui.Selectable(temp_c_string(it), is_selected, size=*default_size) {
                            Reflection.set_enum_value(data, info_enum, info_enum.values[it_index]);
                        }
                        if is_selected ImGui.SetItemDefaultFocus();
                    }

                    ImGui.EndCombo();
                }
            }

            
        case POLYMORPHIC_VARIABLE;
            // @@ ??
        case TYPE;
            // @@
        case OVERLOAD_SET;
            // @@
    }

}


EnumTest :: enum s32 {
    Value1;
    Value2;
    Value3;
    Value4;
}


Weird_Structure :: struct {
    name: string;
    v4: Vector4;
    v3: Vector3;
    b: bool;
    i32: s32;
    i64: int;
    unsigned: u32;
    float_array : [4]float;
    enum_test : EnumTest;
};
weird_structure : Weird_Structure;



main :: () {

    SDL_Init(SDL_INIT_VIDEO);

    window := SDL_CreateWindow("ImGui SDL2+OpenGL example", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 720, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    // Check that the window was successfully created
    if window == null {
        // In the case that the window could not be made...
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    //SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(window);
    if !gl_context {
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }  

    gl_load(*gl, SDL_GL_GetProcAddress);
    //using gl;

    // Setup ImGui binding
    ImGui_ImplSdl_Init(window);

    // Setup style
    ImGui.StyleColorsClassic();
    //ImGui.StyleColorsLight();

    io := ImGui.GetIO();

    clear_color := rgba(0.45, 0.55, 0.60, 1.00);

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
            if ImGui.Button("Inspector", size=*make_vector2(0,0)) show_inspector ^= true;
            //ImGui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.Framerate, io.Framerate);
        }

        if show_inspector {
            //inspect("clear_color", *clear_color);
            inspect("weird_structure", *weird_structure);
            
            //inspect("float_array", *float_array);
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

