// Shared global state is stored here
app : struct {
    window : *SDL_Window = null;

    INITIAL_WINDOW_WIDTH  : s32 : 1280;
    INITIAL_WINDOW_HEIGHT : s32 : 720;

    current_window_width := INITIAL_WINDOW_WIDTH;
    current_window_height := INITIAL_WINDOW_HEIGHT;
    fullscreen := false;

    text_program : GLuint;
    text_vao : GLuint;
    text_vbo : GLuint;

    mesh_program : GLuint;
    mesh_vao : GLuint;

    normals_program : GLuint;
    normals_vao : GLuint;

    Background_Style :: enum #specified {
        SOLID_COLOR :: 0;
        CUSTOM_SHADER :: 1;
    };

    background_style := Background_Style.CUSTOM_SHADER;
    background_solid_color := Vector4.{170./256, 170./256, 170./256, 1.00};
    background_program : GLuint;
    background_vao : GLuint; // Makes GL happy

    modifier_flags : Modifier_Flags; // @Cleanup io should come from one place, probably imgui
    show_ui := true;
    show_global_settings_ui := false;
    show_help_ui := false;
    show_console_ui := false;

    // @Cleanup rename to reference_display_info?
    selection_display_info : Display_Info; // UI will edit this value and apply it to all selected entities

    user_selection : Mesh_Entity;
    user_selection_cursor_text_shown := false;
    user_selection_cursor_text_scale := .4;
    user_selection_max_point_count_for_selectable_entity := 10_000;

    // Set the defaults for the user selection display
    user_selection.is_visible = false;
    user_selection.display_info.points_visible = true;
    user_selection.display_info.points_size = 6;
    user_selection.display_info.points_color = .{1, 0, .8, 1}; // @Volatile Used for the dynamic label text too
    user_selection.display_info.vertex_label_style.show_position = true;
    user_selection.display_info.vertex_label_style.label_color = .{0, 0, 0, 1};

    camera : Camera;
    console : Console;
    entities : [..]*Entity;

    vertex_label_style : Vertex_Label_Style;
    label_limit : s32 = 2000;

    keymap : Keymap;
    keymap_keydown : Keymap;
    settings : User_Settings;

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

entities_iterator :: (entities : *[..]*Entity, body : Code, flags : For_Flags, should_visit : (*Entity)->bool) #expand {
    #assert(flags == 0); // No options are supported

    for entity, entity_index : <<entities {
        if !should_visit(entity) continue;

        `it_index := entity_index;
        `it := entity;
        #insert (remove=#assert(false), break=break entity) body;
    }
}

visible :: #bake_arguments entities_iterator(should_visit = (e)=>(e.is_visible));

#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";
#import "Reflection";
#import "Math";
#import "SDL";
#import "ImGui_";
#import "GL";
#import "Deep_Copy";
#import "Time";
#import "Text_File_Handler";
#import "Hash";
#import "Hash_Table";
#import "freetype255";
#import "System";

#import "geometry";

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
#load "settings.jai";

#import "Compiler";
#run compiler_set_type_info_flags(GL_Procedures, .NO_SIZE_COMPLAINT);
#run compiler_set_type_info_flags(ImGui, .NO_SIZE_COMPLAINT);