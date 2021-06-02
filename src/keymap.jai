
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
    ENTER  :: 2; // unused
    TAB    :: 3; // unused
    F1     :: 4; // unused
    F2     :: 5; // unused
    F3     :: 6; // unused
    F4     :: 7; // unused
    F5     :: 8;
}

to_string :: (using mapping : Single_Key_Mapping) -> string
{
    builder : String_Builder;
    defer free_buffers(*builder);
    if modifier_flags.control_pressed print_to_builder(*builder, "C-");
    if modifier_flags.alt_pressed     print_to_builder(*builder, "A-");
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
        case .ENTER;  print_to_builder(*builder, "Enter");
        case .TAB;    print_to_builder(*builder, "Tab");
        case .F1;     print_to_builder(*builder, "F1");
        case .F2;     print_to_builder(*builder, "F2");
        case .F3;     print_to_builder(*builder, "F3");
        case .F4;     print_to_builder(*builder, "F4");
        case .F5;     print_to_builder(*builder, "F5");
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

    add_key(*app.keymap_keydown, toggle_show_help_ui, "Toggle help UI",  xx #char "h");
    add_key(*app.keymap_keydown, toggle_show_global_settings_ui, "Toggle settings UI",  xx #char "h", .{shift_pressed=true});
    add_key(*app.keymap_keydown, toggle_show_ui, "Toggle entire UI",  xx #char "`");
    add_key(*app.keymap_keydown, toggle_show_console_ui, "Toggle console UI",  xx #char "`", .{control_pressed=true});
    add_key(*app.keymap_keydown, toggle_selection_mode, "Toggle Selection Mode",  xx #char "m");

    add_key(*app.keymap, close_application, "Close application", xx #char "q", .{shift_pressed=true, control_pressed=true});
    add_key(*app.keymap, call_fit_on_screen, "Fit on screen", xx #char "r");
    add_key(*app.keymap, reset_camera, "Reset camera", xx #char "r", .{shift_pressed=true});
    add_key(*app.keymap, select_or_deselect_all, "Select/deselect all items", xx #char "a", .{control_pressed=true});
    add_key(*app.keymap, toggle_current_selection, "Toggle/complement current item selection", xx #char "a", .{alt_pressed=true});

    add_key(*app.keymap, reload_entities, "Reload selected items", xx Special_Key_Code.F5);
    add_key(*app.keymap, cycle_opacity, "Cycle opacity 20%%/50%%/100%% for selected items", xx #char "o");
    add_key(*app.keymap, cycle_normals_visibility, "Cycle normals visibility for selected items", xx #char "n");
    add_key(*app.keymap, cycle_wireframe_width, "Cycle line width for selected items", xx #char "l");
    add_key(*app.keymap, cycle_point_size, "Cycle point size for selected items", xx #char "p");
    add_key(*app.keymap, cycle_point_index_labels, "Cycle point index labels for selected items", xx #char "p", .{shift_pressed=true});
    add_key(*app.keymap, cycle_point_position_labels, "Cycle point position labels for selected items", xx #char "p", .{alt_pressed=true});
    add_key(*app.keymap, clear_labels, "Clear labels", xx #char "x");

    // @Volatile button text in camera control pane should be kept in sync with keymap!
    add_key(*app.keymap, rotate_look_direction_5_cw,   "Rotate  15 deg about selected rotation axis", xx #char "]");
    add_key(*app.keymap, rotate_look_direction_5_ccw,  "Rotate -15 deg about selected rotation axis", xx #char "[");
    add_key(*app.keymap, rotate_look_direction_15_cw,  "Rotate  5  deg about selected rotation axis", xx #char "]", .{shift_pressed=true});
    add_key(*app.keymap, rotate_look_direction_15_ccw, "Rotate -5  deg about selected rotation axis", xx #char "[", .{shift_pressed=true});

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

#scope_file

//
// Bindable procedures
//

call_fit_on_screen             :: () { fit_on_screen(); } // @CompilerBug? why do we need this wrapper
close_application              :: () { app.closing_application = true; }
toggle_show_ui                 :: () { app.show_ui = !app.show_ui; }
toggle_show_global_settings_ui :: () { app.show_global_settings_ui = !app.show_global_settings_ui; }
toggle_show_help_ui            :: () { app.show_ui, app.show_help_ui    = true, !app.show_help_ui; }
toggle_show_console_ui         :: () { app.show_ui, app.show_console_ui = true, !app.show_console_ui; }
toggle_selection_mode          :: () { app.user_selection.is_visible = !app.user_selection.is_visible; }
rotate_look_direction_5_cw     :: () { rotate_look_direction(camera_rotation_axis(),  -5); }
rotate_look_direction_5_ccw    :: () { rotate_look_direction(camera_rotation_axis(),   5); }
rotate_look_direction_15_cw    :: () { rotate_look_direction(camera_rotation_axis(), -15); }
rotate_look_direction_15_ccw   :: () { rotate_look_direction(camera_rotation_axis(),  15); }
rotate_look_direction_45_cw    :: () { rotate_look_direction(camera_rotation_axis(), -45); }
rotate_look_direction_45_ccw   :: () { rotate_look_direction(camera_rotation_axis(),  45); }

cycle_point_index_labels :: () {
    app_style := *app.selection_display_info.vertex_label_style;
    app_style.show_index = !app_style.show_index;
    for app.entities if it.is_selected {
        it.display_info.vertex_label_style.show_index = app_style.show_index;
    }
}

cycle_point_position_labels :: () {
    app_style := *app.selection_display_info.vertex_label_style;
    app_style.show_position = !app_style.show_position;
    for app.entities if it.is_selected {
        it.display_info.vertex_label_style.show_position = app_style.show_position;
    }
}

clear_labels :: () {
    for app.entities if it.is_selected {
        using it.display_info.vertex_label_style;
        show_index, show_position = false, false;
    }
}

cycle_point_size :: () {
    app_info := *app.selection_display_info;
    {
        using app_info;
        if !points_visible {
            points_visible = true;
            points_size = 2;
        } else if points_size == 2 {
            points_size += 2;
        } else {
            points_visible = false;
        }
    }

    for app.entities if it.is_selected {
        it.display_info.points_visible = app_info.points_visible;
        it.display_info.points_size    = app_info.points_size;
    }
}

cycle_wireframe_width :: () {
    app_info := *app.selection_display_info;
    {
        using app_info;
        if !wireframe_visible {
            wireframe_visible = true;
            wireframe_width = 1;
        } else if wireframe_width == 1 {
            wireframe_width += 1;
        } else if wireframe_width == 2 {
            wireframe_width += 1;
        } else {
            wireframe_visible = false;
        }
    }

    for app.entities if it.is_selected {
        it.display_info.wireframe_visible = app_info.wireframe_visible;
        it.display_info.wireframe_width   = app_info.wireframe_width;
    }
}

select_or_deselect_all :: () {
    if !app.entities.count return;
    mode := false;
    for app.entities if it.is_selected mode = true;
    for app.entities it.is_selected = !mode;
}

toggle_current_selection :: () { for app.entities it.is_selected = !it.is_selected; }
reset_camera :: () { init_camera(); }
// debug_junk :: () { c:= app.camera; printv(#code c); }

cycle_opacity :: () {
    for app.entities if it.is_selected {
        if      it.display_info.surface_color.w == 1.  it.display_info.surface_color.w = .5;
        else if it.display_info.surface_color.w == .5  it.display_info.surface_color.w = .2;
        else    it.display_info.surface_color.w =  1.;
    }
}

cycle_normals_visibility :: () {
    for app.entities if it.is_selected {
        it.display_info.normals_visible = !it.display_info.normals_visible;
    }
}
