
// @Cleanup: Maybe just use SDL or ImGui keymap types?

Keymap_Proc_Info :: struct {
    name: string;
    proc: #type () -> ();
}

Single_Key_Mapping :: struct {
    key_code :       u32; // ASCII if key_code >= 32, Special_Key_Code otherwise
    modifier_flags : Modifier_Flags;
    proc_info :      *Keymap_Proc_Info;
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
    if modifier_flags.control_pressed print_to_builder(*builder, "Ctrl-");
    if modifier_flags.alt_pressed     print_to_builder(*builder, "Alt-");
    if modifier_flags.shift_pressed   print_to_builder(*builder, "Shift-");
    if key_code >= 32 {
        upper_case := to_upper(cast(u8) key_code);
        cstr: string;   // This is a dumb way to make a one-character string so you can print it.
        cstr.data  = xx *upper_case;
        cstr.count = 1;
        print_to_builder(*builder, "%", cstr);
    } else if #complete cast(Special_Key_Code)key_code == {
        case .ESCAPE; print_to_builder(*builder, "ESC");
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
    // Triggered on key up
    add_key(*app.keymap, close_application, "close_application", xx Special_Key_Code.ESCAPE);
    add_key(*app.keymap, fit_on_screen, "fit_on_screen", xx #char "r");
    add_key(*app.keymap, cycle_vertex_label_style, "cycle_vertex_label_style", xx #char "v");
    add_key(*app.keymap, cycle_line_style, "cycle_line_style", xx #char "l");
    add_key(*app.keymap, rotate_look_direction_45_cw,  "rotate_look_direction_45_cw",  xx #char "]");
    add_key(*app.keymap, rotate_look_direction_15_cw,  "rotate_look_direction_15_cw",  xx #char "]", .{shift_pressed=true});
    add_key(*app.keymap, rotate_look_direction_45_ccw, "rotate_look_direction_45_ccw", xx #char "[");
    add_key(*app.keymap, rotate_look_direction_15_ccw, "rotate_look_direction_15_ccw", xx #char "[", .{shift_pressed=true});

    // Triggered on key down
    add_key(*app.keymap_keydown, toggle_show_ui, "toggle_show_ui",  xx #char "`");
    add_key(*app.keymap_keydown, toggle_show_help_ui, "toggle_show_help_ui",  xx #char "/");
    add_key(*app.keymap_keydown, toggle_show_help_ui, "toggle_show_help_ui",  xx #char "h");
    add_key(*app.keymap_keydown, toggle_show_console_ui, "toggle_show_console_ui",  xx #char "`", .{control_pressed=true});

    add_key :: (keymap: *Keymap, proc: () -> (), name: string, key_code : u32, modifier_flags : Modifier_Flags = .{}) {
        info := array_add(*keymap.procs); // @TODO: try *`app.keymap.procs
        info.name = name;
        info.proc = proc;

        // @Incomplete: This should be read from a keymap file
        mapping := array_add(*keymap.mappings);
        mapping.key_code = key_code;
        mapping.modifier_flags = modifier_flags;
        mapping.proc_info = info;
    }
}

//
// Bindable procedures
//

close_application :: () {
    app.closing_application = true;
}

toggle_show_ui :: () {
    app.show_ui = !app.show_ui;
}

toggle_show_help_ui :: () {
    app.show_help_ui = !app.show_help_ui;
}

toggle_show_console_ui :: () {
    app.show_console_ui = !app.show_console_ui;
}

rotate_look_direction_45_cw :: () {
    axis := camera_rotation_axis();
    rotate_look_direction(axis, -45);
}

rotate_look_direction_15_cw :: () {
    axis := camera_rotation_axis();
    rotate_look_direction(axis, -15);
}

rotate_look_direction_45_ccw :: () {
    axis := camera_rotation_axis();
    rotate_look_direction(axis, 45);
}

rotate_look_direction_15_ccw :: () {
    axis := camera_rotation_axis();
    rotate_look_direction(axis, 15);
}

#scope_file

#import "Reflection";
