show_main_panel :: (world_axes : Axes_Triad) // @nocommit pointer!!
{
    using app;

    ImGui.Begin("", flags = ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
    defer ImGui.End();
    ImGui.ColorEdit4("Canvas", *clear_color.component, ImGui.ColorEditFlags.NoInputs);
    ImGui.SameLine();
    ImGui.Checkbox("World Axes", *world_axes.origin.visible);
    set_visibility(*world_axes, world_axes.origin.visible);

    #if false {
        if ImGui.Button("Demo Window", size=*V2_ZERO) show_demo_window ^= true;
        if show_demo_window {
            ImGui.SetNextWindowPos(*make_vector2(650, 20), ImGui.Cond.FirstUseEver, *V2_ZERO);
            ImGui.ShowDemoWindow(*show_demo_window);
        }
    }

    if ImGui.Button("Reset Window          ", size=*V2_ZERO) SDL_SetWindowSize(window, app.INITIAL_WINDOW_WIDTH, app.INITIAL_WINDOW_HEIGHT);
    if ImGui.Button("Reset Camera       (R)", size=*V2_ZERO) fit_on_screen();
    if ImGui.Button("Cycle vertex style (V)", size=*V2_ZERO) cycle_vertex_label_style();
    if ImGui.Button("Cycle line style   (L)", size=*V2_ZERO) cycle_line_style();

    imgui_label :: (label : string, ptr : *void) -> *u8 {
        return to_c_string(concatenate(label, tprint("##%", ptr)));
    }

    entity_to_remove := -1;
    for entities {
        mesh := get_mesh(it);
        if mesh {

            ShowTooltip :: (description : string) #expand {
                if (ImGui.IsItemHovered()) {
                    ImGui.BeginTooltip();
                    // ImGui.PushTextWrapPos(450);
                    ImGui.TextUnformatted(description);
                    // ImGui.PopTextWrapPos();
                    ImGui.EndTooltip();
                }
            }

            // Entity index used to refer to geometry in console
            ImGui.Text(to_c_string(tprint("%", it_index)));

            // Remove button
            ImGui.SameLine();
            if ImGui.Button(imgui_label("Remove", it), size=*V2_ZERO) {
                entity_to_remove = it_index;
                break;
            }

            // Color picker
            ImGui.SameLine();
            ImGui.ColorEdit4(imgui_label("##color", it), *mesh.color.component, ImGui.ColorEditFlags.NoInputs);

            // Toggle visibility checkbox
            ImGui.SameLine();
            ImGui.Checkbox(imgui_label("##visible", it), *mesh.visible);
            ShowTooltip("Visible");

            // Extra settings accessible with RMB
            ImGui.SameLine();
            ImGui.Text("...");
            if ImGui.BeginPopupContextItem(imgui_label("##context_menu", it)) {
                defer ImGui.EndPopup();

                // Combo box to select display mode enum value
                info_enum := type_info(type_of(mesh.display_mode));
                value := get_enum_value(*mesh.display_mode, info_enum);
                value_name := "";
                for info_enum.names {
                    if value == info_enum.values[it_index]  value_name = it;
                }
                if ImGui.BeginCombo("Display mode", temp_c_string(value_name)) {
                    for info_enum.names {
                        is_selected := value == info_enum.values[it_index];
                        if ImGui.Selectable(temp_c_string(it), is_selected, size=*V2_ZERO) {
                            set_enum_value(*mesh.display_mode, info_enum, info_enum.values[it_index]);
                        }
                        if is_selected ImGui.SetItemDefaultFocus();
                    }

                    ImGui.EndCombo();
                }

                // Toggle visibility checkbox
                ImGui.Checkbox(imgui_label("Visible", it), *mesh.visible);

                // Toggle wireframe checkbox
                if it.type == .MESH || it.type == .POLYGON_SOUP {
                    ImGui.Checkbox(imgui_label("Wireframe", it), *mesh.wireframe);
                }
            }

            // Write filename
            if mesh.fully_pathed_filename.count {
                ImGui.SameLine();
                ImGui.Text(path_filename(mesh.fully_pathed_filename)); // @CompilerBug?
            }
        }
    }

    if entity_to_remove >= 0 && entity_to_remove < entities.count {
        deinit(entities[entity_to_remove]);
        free(entities[entity_to_remove]);
        array_ordered_remove_by_index(*entities, entity_to_remove);
    }

    // @FIXME
    // if ImGui.InputText("Cursor Text", cursor_text.data, xx cursor_text.count) {
    //     // cursor_text.count = str_length(cursor_text.data);
    // }
    // ImGui.Text("%", cursor_text);
}

show_camera_controls :: () {
    window_pos := make_vector2(ImGui.GetIO().DisplaySize.x - 10., 10.);
    window_pivot := make_vector2(1, 0);

    using ImGui.WindowFlags;

    ImGui.SetNextWindowPos(*window_pos, .Always, *window_pivot);
    // ImGui.SetNextWindowContentWidth(135.);
    // ImGui.SetNextWindowBgAlpha(.3);
    ImGui.Begin("Camera shortcuts", flags = NoTitleBar | AlwaysAutoResize | NoMove /*| NoNav*/);

    X_AXIS :: Vector3.{1, 0, 0};
    Y_AXIS :: Vector3.{0, 1, 0};
    Z_AXIS :: Vector3.{0, 0, 1};

    // @Incomplete Interpolate the motion

    if ImGui.Button("+X ", size=*V2_ZERO) {
        set_look_direction(direction=X_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("+Y ", size=*V2_ZERO) {
        set_look_direction(direction=Y_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("+Z ", size=*V2_ZERO) {
        set_look_direction(direction=Z_AXIS, up=Y_AXIS);
    }

    if ImGui.Button("-X ", size=*V2_ZERO) {
        set_look_direction(direction=-X_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("-Y ", size=*V2_ZERO) {
        set_look_direction(direction=-Y_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("-Z ", size=*V2_ZERO) {
        set_look_direction(direction=-Z_AXIS, up=Y_AXIS);
    }

    ImGui.Separator();

    right_label, left_label, amount := "<< ", " >>", 45.;
    if app.modifier_flags.shift_pressed {
        right_label, left_label, amount = " < ", " > ", 15.;
    }

    if ImGui.Button(to_c_string(right_label), size=*V2_ZERO) {
        // rotate_look_direction_around_up_direction(amount);
        rotate_look_direction_around_look_along(amount);
    }
    ImGui.SameLine();
    if ImGui.Button("XYZ", size=*V2_ZERO) {
        // Having up = Z_AXIS instead is actually kinda nice, hmm...
        up := normalize(cross(.{-1, 1, 0}, .{-1, -1, -1}));
        set_look_direction(direction=.{-1, -1, -1}, up=up);
    }
    ImGui.SameLine();
    if ImGui.Button(to_c_string(left_label), size=*V2_ZERO) {
        // rotate_look_direction_around_up_direction(-amount);
        rotate_look_direction_around_look_along(-amount);
    }

    if ImGui.Button(" Reset Focus ", size=*V2_ZERO) {
        app.camera.look_position = .{0, 0, 0};
    }

    // @Incomplete add perspective/orthographic toggle
    // @Incomplete add button to reset look position

    ImGui.End();
}
