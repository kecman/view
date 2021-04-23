
// @Cleanup: Maybe just use SDL or ImGui keymap types?

Keymap_Proc_Info :: struct {
    name: string;
    proc: #type () -> ();
}

Single_Key_Mapping :: struct {
    key_code :       u32; // ASCII if key_code >= 32, Special_Key_Code otherwise
    modifier_flags : Modifier_Flags;
    proc_info_index : int;
}

// Compile-time check to ensure we don't stomp the ASCII key codes we want
#assert(enum_highest_value(Special_Key_Code) < 32);

Special_Key_Code :: enum u32 #specified {
    ESCAPE :: 1;
    // ENTER  :: 2;
    // TAB    :: 3;
    // F1     :: 4;
}

to_string :: (using mapping : Single_Key_Mapping) -> string
{
    builder : String_Builder;
    defer free_buffers(*builder);
    if modifier_flags.control_pressed print_to_builder(*builder, "C-");
    if modifier_flags.alt_pressed     print_to_builder(*builder, "M-");
    if modifier_flags.shift_pressed   print_to_builder(*builder, "S-");
    if key_code >= 32 {
        // upper_case := to_upper(cast(u8) key_code);
        upper_case := cast(u8) key_code;
        cstr: string;   // This is a dumb way to make a one-character string so you can print it.
        cstr.data  = xx *upper_case;
        cstr.count = 1;
        print_to_builder(*builder, "%", cstr);
    } else if #complete cast(Special_Key_Code)key_code == {
        case .ESCAPE; print_to_builder(*builder, "Esc");
    }

    return builder_to_string(*builder);
}

Keymap :: struct {
    // These are fixed at startup. When you load a keymap, we bind keys to procedures from this array.
    procs : [..] Keymap_Proc_Info;

    mappings : [..] Single_Key_Mapping;
}

init_keymap :: ()
{
    // @Incomplete that we don't have clashing key mappings

    add_key(*app.keymap_keydown, toggle_show_help_ui, "toggle_show_help_ui",  xx #char "h");
    add_key(*app.keymap_keydown, toggle_show_global_settings_ui, "toggle_show_global_settings_ui",  xx #char "h", .{shift_pressed=true});
    add_key(*app.keymap_keydown, toggle_show_ui, "toggle_show_ui",  xx #char "`");
    add_key(*app.keymap_keydown, toggle_show_console_ui, "toggle_show_console_ui",  xx #char "`", .{control_pressed=true});

    add_key(*app.keymap, close_application, "close_application", xx #char "q", .{shift_pressed=true, control_pressed=true});
    add_key(*app.keymap, call_fit_on_screen, "fit_on_screen", xx #char "r");
    add_key(*app.keymap, reset_camera, "reset_camera", xx #char "r", .{shift_pressed=true});

    add_key(*app.keymap, cycle_line_width, "cycle_line_width", xx #char "l");
    add_key(*app.keymap, cycle_point_size, "cycle_point_size", xx #char "p");
    add_key(*app.keymap, cycle_point_index_labels, "cycle_point_index_labels", xx #char "p", .{shift_pressed=true});
    add_key(*app.keymap, cycle_point_position_labels, "cycle_point_position_labels", xx #char "p", .{alt_pressed=true});
    add_key(*app.keymap, clear_labels, "clear_labels", xx #char "x");

    add_key(*app.keymap, rotate_look_direction_15_cw,  "rotate_look_direction_15_cw",  xx #char "]");
    add_key(*app.keymap, rotate_look_direction_15_ccw, "rotate_look_direction_15_ccw", xx #char "[");
    add_key(*app.keymap, rotate_look_direction_45_cw,  "rotate_look_direction_45_cw",  xx #char "]", .{shift_pressed=true});
    add_key(*app.keymap, rotate_look_direction_45_ccw, "rotate_look_direction_45_ccw", xx #char "[", .{shift_pressed=true});
    add_key(*app.keymap, rotate_look_direction_5_cw,   "rotate_look_direction_5_cw",   xx #char "]", .{alt_pressed=true});
    add_key(*app.keymap, rotate_look_direction_5_ccw,  "rotate_look_direction_5_ccw",  xx #char "[", .{alt_pressed=true});
    // add_key(*app.keymap, debug_junk, "debug_junk", xx #char " ");

    add_key :: (keymap : *Keymap, proc : () -> (), name : string, key_code : u32, modifier_flags : Modifier_Flags = .{}) {
        info := array_add(*keymap.procs);
        info.name = name;
        info.proc = proc;

        // @Incomplete: This should be read from a keymap file
        mapping := array_add(*keymap.mappings);
        mapping.key_code = key_code;
        mapping.modifier_flags = modifier_flags;
        mapping.proc_info_index = keymap.procs.count - 1;
    }
}

//
// Bindable procedures
//

call_fit_on_screen             :: () { fit_on_screen(); } // @CompilerBug? why do we need this wrapper
close_application              :: () { app.closing_application = true; }
toggle_show_ui                 :: () { app.show_ui = !app.show_ui; }
toggle_show_global_settings_ui :: () { app.show_global_settings_ui = !app.show_global_settings_ui; }
toggle_show_help_ui            :: () { app.show_ui, app.show_help_ui    = true, !app.show_help_ui; }
toggle_show_console_ui         :: () { app.show_ui, app.show_console_ui = true, !app.show_console_ui; }
rotate_look_direction_5_cw     :: () { rotate_look_direction(camera_rotation_axis(),  -5); }
rotate_look_direction_5_ccw    :: () { rotate_look_direction(camera_rotation_axis(),   5); }
rotate_look_direction_15_cw    :: () { rotate_look_direction(camera_rotation_axis(), -15); }
rotate_look_direction_15_ccw   :: () { rotate_look_direction(camera_rotation_axis(),  15); }
rotate_look_direction_45_cw    :: () { rotate_look_direction(camera_rotation_axis(), -45); }
rotate_look_direction_45_ccw   :: () { rotate_look_direction(camera_rotation_axis(),  45); }
cycle_point_index_labels       :: () { using app.vertex_label_style; show_index    = !show_index; }
cycle_point_position_labels    :: () { using app.vertex_label_style; show_position = !show_position; }
clear_labels                   :: () { using app.vertex_label_style; show_index = false; show_position = false; }
cycle_point_size               :: () { using app.vertex_label_style; if point_size == 0 point_size = 2; else if point_size == 2 point_size = 4; else point_size = 0; }
cycle_line_width               :: () { using app.vertex_label_style; if line_width == 1 line_width = 2; else if line_width == 2 line_width = 3; else line_width = 1; }
reset_camera                   :: () { init_camera(); }
// debug_junk                     :: () { c:= app.camera; printv(#code c); }

#scope_file

#import "Reflection";
