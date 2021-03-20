show_global_settings_ui :: (world_axes : *Axes_Triad)
{
    if !app.show_global_settings_ui return;

    using app;

    ImGui.SetNextWindowPos(pos=*make_vector2(10, 10), pivot=*V2_ZERO);
    ImGui.Begin("Main Panel", flags = ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
    defer ImGui.End();
    ImGui.ColorEdit4("Background Color", *clear_color.component, ImGui.ColorEditFlags.NoInputs);
    ImGui.Checkbox("World Axes", *world_axes.visible);

    // if ImGui.Button("Reset Window          ", size=*V2_ZERO) SDL_SetWindowSize(window, app.INITIAL_WINDOW_WIDTH, app.INITIAL_WINDOW_HEIGHT);
    // if ImGui.Button("Reset Camera       (R)", size=*V2_ZERO) fit_on_screen();
    // if ImGui.Button("Cycle vertex style (V)", size=*V2_ZERO) cycle_vertex_label_style();
    // if ImGui.Button("Cycle line style   (L)", size=*V2_ZERO) cycle_line_style();

    #if false {
        ImGui.SetNextWindowPos(*make_vector2(650, 20), ImGui.Cond.FirstUseEver, *V2_ZERO);
        SHOW_DEMO_WINDOW :: true;
        ImGui.ShowDemoWindow(*SHOW_DEMO_WINDOW);
    }
}

show_scene_ui :: ()
{
    if !entities.count return;

    using app;

    ImGui.SetNextWindowPos(pos=*make_vector2(10, 10), pivot=*V2_ZERO);
    ImGui.Begin("Main Panel", flags = ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
    defer ImGui.End();

    imgui_label :: (label : string, ptr : *void) -> *u8 {
        Push_Temporary();
        return to_c_string(concatenate(label, tprint("##%", ptr)));
    }

    entity_to_remove := -1;
    for entities {
        mesh := get_mesh(it);
        if mesh {

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
            ImGui.Checkbox(imgui_label("##visible", it), *it.visible);
            ShowTooltip("Visible");

            // Extra settings accessible with RMB
            ImGui.SameLine();
            ImGui.Text("...");
            ShowTooltip("Show item options");
            if ImGui.BeginPopupContextItem(imgui_label("##context_menu", it)) {
                defer ImGui.EndPopup();

                if mesh.fully_pathed_filename.count {
                    ImGui.Text(path_filename(mesh.fully_pathed_filename)); // @CompilerBug?
                }

                // Toggle visibility checkbox
                ImGui.Checkbox(imgui_label("Visible", it), *it.visible);

                // Toggle wireframe checkbox
                if it.type == .MESH || it.type == .POLYGON_SOUP {
                    ImGui.Checkbox(imgui_label("Wireframe   ", it), *mesh.wireframe);
                }

                ImGui.PushItemWidth(-1);
                combo_box("", *mesh.display_mode, type_info(type_of(mesh.display_mode)));

                if it.type == {
                    case .POLYLINE_SOUP2;

                        using soup := cast(*Polyline_Soup2_Entity)it;
                        ImGui.Text(to_c_string(tprint("# points    %", point_count(shape))));
                        ImGui.Text(to_c_string(tprint("# polylines %", shape.polylines.count)));

                    case .POLYLINE_SOUP3;

                        using soup := cast(*Polyline_Soup3_Entity)it;
                        ImGui.Text(to_c_string(tprint("# points    %", point_count(shape))));
                        ImGui.Text(to_c_string(tprint("# polylines %", shape.polylines.count)));

                    case .POLYGON_SOUP;

                        using soup := cast(*Polygon_Soup_Entity)it;
                        ImGui.Text(to_c_string(tprint("# points   %", point_count(shape))));
                        ImGui.Text(to_c_string(tprint("# polygons %", shape.polygons.count)));

                    case .MESH;

                        mesh := cast(*Mesh_Entity)it;
                        ImGui.Text(to_c_string(tprint("# points    %", mesh.mesh.positions.count)));
                        ImGui.Text(to_c_string(tprint("# triangles %", mesh.mesh.indices.count / 3)));
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
    defer ImGui.End();

    X_AXIS :: Vector3.{1, 0, 0};
    Y_AXIS :: Vector3.{0, 1, 0};
    Z_AXIS :: Vector3.{0, 0, 1};

    // @Incomplete Interpolate the motion

    ImGui.Columns(3, border=false);
    if ImGui.Button("+X ", size=*V2_ZERO) {
        set_look_direction(direction=X_AXIS, up=Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("+Y ", size=*V2_ZERO) {
        set_look_direction(direction=Y_AXIS, up=Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("+Z ", size=*V2_ZERO) {
        set_look_direction(direction=Z_AXIS, up=Y_AXIS);
    }
    ImGui.NextColumn();

    if ImGui.Button("-X ", size=*V2_ZERO) {
        set_look_direction(direction=-X_AXIS, up=Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("-Y ", size=*V2_ZERO) {
        set_look_direction(direction=-Y_AXIS, up=Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("-Z ", size=*V2_ZERO) {
        set_look_direction(direction=-Z_AXIS, up=Y_AXIS);
    }
    ImGui.NextColumn();

    right_label, left_label, amount := "<<<", ">>>", 45.;
    if app.modifier_flags.shift_pressed {
        right_label, left_label, amount = "<< ", " >>", 15.;
    } else if app.modifier_flags.alt_pressed {
        right_label, left_label, amount = " < ", " > ", 1.;
    }

    if ImGui.Button(to_c_string(right_label), size=*V2_ZERO) {
        axis := camera_rotation_axis();
        rotate_look_direction(axis, amount);
    }
    ImGui.NextColumn();
    if ImGui.Button("XYZ", size=*V2_ZERO) {
        up := normalize(cross(.{-1, 1, 0}, .{-1, -1, -1}));
        set_look_direction(direction=.{-1, -1, -1}, up=up);
    }
    ImGui.NextColumn();
    if ImGui.Button(to_c_string(left_label), size=*V2_ZERO) {
        axis := camera_rotation_axis();
        rotate_look_direction(axis, -amount);
    }
    ImGui.NextColumn();

    ImGui.Columns(1, border=false);

    ImGui.PushItemWidth(-1);
    combo_box("", *app.camera_rotation_axis, type_info(type_of(app.camera_rotation_axis)));
    ShowTooltip("Scene Rotation Axis");

    ImGui.PushItemWidth(-1);
    if ImGui.Button(" Reset Focus ", size=*V2_ZERO) {
        app.camera.look_position = .{0, 0, 0};
    }

    // @Incomplete add perspective/orthographic toggle
    // @Incomplete add button to reset look position
}

show_help_ui :: ()
{
    if !app.show_help_ui return;

    window_pos := make_vector2(ImGui.GetIO().DisplaySize.x - 10., 10.);
    window_pivot := make_vector2(1, 0);

    ImGui.SetNextWindowPos(pos=*window_pos, pivot=*window_pivot);
    ImGui.Begin("##show_help_ui", flags = ImGui.WindowFlags.NoTitleBar | .AlwaysAutoResize | .NoMove /*| .NoNav*/);
    defer ImGui.End();

    ImGui.Columns(2);
    ImGui.SetColumnWidth(-1, 80);
    ImGui.Text("Binding");
    ImGui.NextColumn();
    // ImGui.SetColumnWidth(-1, 250);
    ImGui.Text("Function");
    ImGui.NextColumn();
    ImGui.Separator();

    for app.keymap.mappings {
        ImGui.Text(to_c_string(tprint("%", to_string(it))));
        ImGui.NextColumn();
        ImGui.Text(to_c_string(tprint("%", it.proc_info.name)));
        ImGui.NextColumn();
    }

    for app.keymap_keydown.mappings {
        ImGui.Text(to_c_string(tprint("%", to_string(it))));
        ImGui.NextColumn();
        ImGui.Text(to_c_string(tprint("%", it.proc_info.name)));
        ImGui.NextColumn();
    }
    ImGui.Columns(1);
    ImGui.Text("                                          "); // @Hack

    // @Incomplete add a message about where the keymap is for editing
}

#scope_file

// Combo box to select display mode enum value
combo_box :: (label : string, data: *void, info_enum: *Type_Info_Enum) {
    value := get_enum_value(data, info_enum);
    value_name := "";
    for info_enum.names {
        if value == info_enum.values[it_index]  value_name = it;
    }
    if ImGui.BeginCombo(to_c_string(label), temp_c_string(value_name)) {
        for info_enum.names {
            is_selected := value == info_enum.values[it_index];
            if ImGui.Selectable(temp_c_string(it), is_selected, size=*V2_ZERO) {
                set_enum_value(data, info_enum, info_enum.values[it_index]);
            }
            if is_selected ImGui.SetItemDefaultFocus();
        }

        ImGui.EndCombo();
    }
}

ShowTooltip :: (description : string) #expand {
    if (ImGui.IsItemHovered()) {
        ImGui.BeginTooltip();
        // ImGui.PushTextWrapPos(450);
        ImGui.TextUnformatted(description);
        // ImGui.PopTextWrapPos();
        ImGui.EndTooltip();
    }
}