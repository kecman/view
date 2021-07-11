// Shared global state is stored here
App :: struct {
    window : *SDL_Window = null;

    INITIAL_WINDOW_WIDTH  : s32 : 1440;
    INITIAL_WINDOW_HEIGHT : s32 : 900;

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

    aabb_program : GLuint;
    aabb_vao : GLuint;

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
    selection_display_info.points_visible = false;
    selection_display_info.normals_visible = false;
    selection_display_info.wireframe_visible = false;
    selection_display_info.surface_visible = false;
    selection_display_info.aabb_visible = false;

    user_selection : Mesh_Entity;
    user_selection_cursor_text_shown := false;
    user_selection_cursor_text_scale := .4;
    user_selection_max_point_count_for_selectable_entity := 100_000;

    // Set the defaults for the user selection display
    user_selection.is_visible = false;
    user_selection.display_info.points_visible = true;
    user_selection.display_info.points_size = 6;
    user_selection.display_info.points_color = .{1, 0, .8, 1}; // @Volatile Used for the dynamic label text too
    user_selection.display_info.vertex_label_style.show_position = true;
    user_selection.display_info.vertex_label_style.label_color = .{0, 0, 0, 1};

    // Checkbox sweep mode is enabled while LMB is held down if it was clicked on a sweepable checkbox, the mouse will be constrained to move only up and down and the inverse of the state of the checkbox just before the click will be set on all the checkboxes that get swept
    checkbox_sweep_mode := false;
    checkbox_sweep_mode_mouse_min_x : s32;
    checkbox_sweep_mode_mouse_max_x : s32;
    checkbox_sweep_mode_state_to_set := false;

    camera : Camera;
    console : Console;
    entities : [..]*Entity;

    vertex_label_style : Vertex_Label_Style;
    label_limit : s32 = 2000;

    keymap : Keymap;
    keymap_keydown : Keymap;
    settings : User_Settings;

    closing_application := false; // Set this to true to close the application
    show_imgui_demo_window := true;
}

app : App;

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

// @Cleanup remove, it's unused and not very helpful
Selected_Or_Hovered :: (entities : *[..]*Entity, body : Code, flags : For_Flags) #expand {
    #assert(flags == 0); // No options are supported

    `it_index : int;
    `it : *Entity;

    count := 0;
    for entity, entity_index : <<entities if entity.is_selected {
        it_index = entity_index;
        it = entity;
        #insert (remove=#assert(false), break=break entity) body;
        count += 1;
    }

    if count == 0 for entity, entity_index : <<entities if entity.is_hovered {
        it_index = entity_index;
        it = entity;
        #insert (remove=#assert(false), break=break entity) body;
    }
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";
#import "Reflection";
#import "Math";
#import "SDL";
#import "GL";
#import "Deep_Copy";
#import "Time";
#import "Text_File_Handler";
#import "Hash";
#import "Hash_Table";
#import "freetype255";
#import "System";
// #import "Window_Type";
// Simp :: #import "Simp";

#import "geometry";

ImGui :: #import "jai-imgui"(LINK_STATIC=true);
#load "modules/jai-imgui/backends/imgui_impl_sdl.jai"; // SDL platform backend
#load "modules/jai-imgui/backends/imgui_impl_opengl3.jai"; // OpenGL renderer backend

#import "geometry";
#load "axes.jai";
#load "selection_mode.jai";
#load "numeric.jai";
#load "geometric_operations.jai";
#load "io_obj.jai";
#load "io_wkt.jai";
#load "rendering.jai";
#load "rendering_utils.jai";
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