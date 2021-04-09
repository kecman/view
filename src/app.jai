// Shared global state is stored here
app : struct {
    window : *SDL_Window = null;

    INITIAL_WINDOW_WIDTH  : s32 : 1280;
    INITIAL_WINDOW_HEIGHT : s32 : 720;

    current_window_width := INITIAL_WINDOW_WIDTH;
    current_window_height := INITIAL_WINDOW_HEIGHT;
    fullscreen := false;

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

    modifier_flags : Modifier_Flags; // @Cleanup io should come from one place, probably imgui
    show_ui := true;
    show_global_settings_ui := false;
    show_help_ui := false;
    show_console_ui := false;

    camera : Camera;
    console : Console;
    entities : [..]*Entity;

    vertex_label_style : VertexLabelStyle;
    label_limit := 2000;

    keymap : Keymap;
    keymap_keydown : Keymap;

    closing_application := false; // Set this to true to close the application
}

current_window_aspect_ratio_width_over_height :: () -> float {
    return cast(float) app.current_window_width / cast(float) app.current_window_height;
}

Modifier_Flags :: struct {
    shift_pressed   := false;
    control_pressed := false;
    alt_pressed     := false;
}

#import "Basic";
#import "File";
#import "String";
#import "Reflection";
#import "Math";
#import "SDL";
#import "ImGui_";
#import "GL";

#load "modules/ImGui_/examples/imgui_sdl_gl.jai";

#import "geometry";
#load "numeric.jai";
#load "geometric_operations.jai";
#load "io_obj.jai";
#load "io_wkt.jai";
#load "rendering.jai";
#load "font.jai";
#load "carpet.jai";
#load "camera.jai";
#load "console.jai";
#load "commands.jai";
#load "entities.jai";
#load "mesh_utils.jai";
#load "ui.jai";
#load "shapes.jai";
#load "keymap.jai";
#load "inspector.jai";

#import "Compiler";
#run compiler_set_type_info_flags(GL_Procedures, .NO_SIZE_COMPLAINT);
#run compiler_set_type_info_flags(ImGui, .NO_SIZE_COMPLAINT);