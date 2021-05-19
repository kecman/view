V2_ZERO :: Vector2.{0, 0};
WINDOW_BORDER_UI_OFFSET :: Vector2.{10, 10};

show_global_settings_ui :: (world_axes : *Axes_Triad)
{
    if !app.show_global_settings_ui return;

    using app;

    ImGui.SetNextWindowPos(pos=*WINDOW_BORDER_UI_OFFSET, pivot=*V2_ZERO);
    ImGui.Begin("Main Panel", flags = ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
    defer ImGui.End();
    defer if entities.count ImGui.Separator();

    combo_box("Background", *app.background_style, type_info(Background_Style));
    if app.background_style == .SOLID_COLOR {
        ImGui.ColorEdit4("Background Color", *background_solid_color.component, ImGui.ColorEditFlags.NoInputs);
    }
    ImGui.Checkbox("World Axes", *world_axes.visible);

    // :UserConfig add a button to overwrite the user settings file with new defaults here?
    inspect("User Settings", *app.settings);
    clamp_user_settings();

    if ImGui.TreeNode("%", "Label Settings") {
        defer ImGui.TreePop();
        ImGui.Unindent(ImGui.GetTreeNodeToLabelSpacing());
        defer ImGui.Indent(ImGui.GetTreeNodeToLabelSpacing());

        ImGui.Checkbox("Index labels", *vertex_label_style.show_index);
        ImGui.SameLine();
        ImGui.Checkbox("Position labels", *vertex_label_style.show_position);
        trailing_width : s32 = xx vertex_label_style.format_float.trailing_width;
        ImGui.InputInt("Float decimals", *trailing_width);
        vertex_label_style.format_float.trailing_width = clamp(trailing_width, 0, 12);
        Show_Tooltip("Number of digits following the decimal point");
        combo_box("Float format", *vertex_label_style.format_float.mode, type_info(FormatFloat.Mode));
        ImGui.DragFloat("Label scale", *vertex_label_style.label_scale, .005, .2, 1., display_format="%.3f");
        ImGui.ColorEdit4("Label color", *vertex_label_style.label_color.component, ImGui.ColorEditFlags.NoInputs);

        the_label_limit : s32 = xx label_limit;
        ImGui.InputInt("Label limit", *the_label_limit);
        label_limit = the_label_limit;
        if label_limit > 2000 {
            color := ImVec4.{1., .4, .4, 1.};
            ImGui.TextColored(*color, "%s", "Warning: label limit > 2000 may be slow");
        }

        // @Speed Only need to do this if something changed
        update_entities_using_default_vertex_label_style();
    }

    if current_window_width != INITIAL_WINDOW_WIDTH && current_window_height != INITIAL_WINDOW_HEIGHT {
        if ImGui.Button("Reset Window", size=*V2_ZERO) {
            SDL_SetWindowSize(window, app.INITIAL_WINDOW_WIDTH, app.INITIAL_WINDOW_HEIGHT);
        }
    }

    #if false {
    ImGui.SetNextWindowPos(*make_vector2(650, 20), ImGui.Cond.FirstUseEver, *V2_ZERO);
    SHOW_DEMO_WINDOW :: true;
    ImGui.ShowDemoWindow(*SHOW_DEMO_WINDOW);
    }
}

show_scene_ui :: ()
{
    using app;

    if !entities.count return;

    ImGui.SetNextWindowPos(pos=*WINDOW_BORDER_UI_OFFSET, pivot=*V2_ZERO);
    ImGui.Begin("Main Panel", flags = ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar);
    defer ImGui.End();

    imgui_label :: (label : string, ptr : *void) -> *u8 {
        Push_Temporary();
        return to_c_string(concatenate(label, tprint("##%", ptr)));
    }

    any_visibility_toggled := false;


    entity_to_remove := -1;
    for entities {
        mesh := get_mesh(it);
        if mesh {

            // Toggle visibility checkbox
            visibility_toggled := checkbox_press_or_sweep_to_toggle(*it.display_info.visible, *it.display_info.visible_sweep_hovered, imgui_label("##Visible", it));
            Show_Tooltip("Visible");
            any_visibility_toggled = any_visibility_toggled || visibility_toggled;

            // Remove button
            ImGui.SameLine();
            if ImGui.Button(imgui_label("Remove", it), size=*V2_ZERO) {
                entity_to_remove = it_index;
            }

            // Color picker
            ImGui.SameLine();
            if it.display_info.display_mode == .NORMALS {
                ImGui.TextDisabled("NR.");
            } else {
                ImGui.ColorEdit4(imgui_label("##color", it), *it.display_info.color.component, ImGui.ColorEditFlags.NoInputs);
            }
            if ImGui.IsItemClicked(1) {
                cycle_display_mode(*it.display_info.display_mode);
            }

            // Entity index used to refer to geometry in console or annotate the text following ther cursor when adding to the user selection
            if app.show_console_ui || app.user_selection.display_info.visible {
                ImGui.SameLine();
                label := to_c_string(tprint("#%", it_index));
                if mesh.positions.count <= app.user_selection_max_point_count_for_selectable_entity {
                    ImGui.Text(label);
                    Show_Tooltip("Entity index for console commands\nand user selection cursor labels");
                } else {
                    ImGui.TextDisabled(label);
                    Show_Tooltip("Entity index for console commands\nand user selection cursor labels\nIncrease max point count to select this entity");
                }
                ImGui.SameLine();
            }

            // Write filename
            ImGui.SameLine();
            if it.fully_pathed_filename.count {
                text := entity_filename_with_generation_index(<<it);

                loaded_time_text := filetime_to_readable_date(it.loaded_filetime);
                delta_time := get_current_file_time() - it.loaded_filetime;
                FADE_TIME_SECS := 1;
                color := Vector4.{1, 1, 1, 1};
                if delta_time < xx (FADE_TIME_SECS * 10_000_000.) {
                    alpha := clamp(delta_time / (FADE_TIME_SECS * 10_000_000.), 0., 1.);
                    color = lerp(Vector4.{0, 1, 0, 1}, Vector4.{1, 1, 1, 1}, alpha);
                }

                ImGui.PushStyleColor(xx ImGui.Col.Text, *color);
                if ImGui.Selectable(to_c_string(text), *it.is_selected, size=*V2_ZERO) {
                    if !io().KeyCtrl it.is_selected = !it.is_selected;
                }
                ImGui.PopStyleColor();
            } else {
                ImGui.Selectable("---", *it.is_selected, size=*V2_ZERO);
            }
            Show_Tooltip("RMB: Show item/selection context menu\nLMB: Focus item\nCtrl+LMB: Select item");
            if ImGui.IsItemClicked() {
                if !io().KeyCtrl fit_on_screen(it);
            }
            was_flash_hovered := it.display_info.flash_hovered;
            if ImGui.IsItemHovered() {
                it.display_info.flash_hovered = true;
                it.display_info.flash_wave_dt += io().DeltaTime;
            } else if was_flash_hovered {
                it.display_info.flash_hovered = false;
                it.display_info.flash_wave_dt = 0;
            }

            if ImGui.BeginPopupContextItem(imgui_label("##context_menu", xx it_index)) {
                defer ImGui.EndPopup();

                if !it.is_selected {
                    if it.fully_pathed_filename.count {

                        text := entity_fully_pathed_filename_with_generation_index(<<it);
                        ImGui.Text(text);
                    }

                    loaded_time_text := filetime_to_readable_date(it.loaded_filetime);
                    ImGui.Text("% %", "Loaded at", loaded_time_text);
                    ImGui.SameLine();
                    if it.fully_pathed_filename.count && ImGui.SmallButton(imgui_label("Reload", it)) {
                        entity := load_entity_from_file(it.fully_pathed_filename);
                        replace_entity(it, it_index, entity);
                    }

                    if it.type == {
                        case .POLYLINE_SOUP2;

                            using soup := cast(*Polyline_Soup2_Entity)it;
                            ImGui.Text(to_c_string(tprint("#points, #polylines = %, %", point_count(shape), shape.polylines.count)));

                        case .POLYLINE_SOUP3;

                            using soup := cast(*Polyline_Soup3_Entity)it;
                            ImGui.Text(to_c_string(tprint("#points, #polylines = %, %", point_count(shape), shape.polylines.count)));

                        case .POLYGON_SOUP;

                            using soup := cast(*Polygon_Soup_Entity)it;
                            ImGui.Text(to_c_string(tprint("#points, #polygons = %, %", point_count(shape), shape.polygons.count)));

                        case .MESH;

                            mesh := cast(*Mesh_Entity)it;
                            ImGui.Text(to_c_string(tprint("#points, #triangles = %, %", mesh.mesh.positions.count, mesh.mesh.indices.count / 3)));
                    }

                    maybe_update_render_info(*it.render_info, *it.mesh);
                    aabb := it.render_info.bounding_aabb;
                    ImGui.Text(to_c_string(tprint("AABB [%, %, %], [%, %, %]",
                                                  aabb.min_point.x, aabb.min_point.y, aabb.min_point.z,
                                                  aabb.max_point.x, aabb.max_point.y, aabb.max_point.z)));

                    ImGui.Separator();

                    combo_box("", *it.display_info.display_mode, type_info(type_of(it.display_info.display_mode)));
                    ImGui.SameLine();
                    ImGui.PushItemWidth(70);
                    ImGui.DragFloat(imgui_label("##Opacity", it), *it.display_info.color.w, v_speed=.005, v_min=0., v_max=1.);
                    ImGui.PopItemWidth();
                    Show_Tooltip("Opacity");

                    if it.type == .MESH || it.type == .POLYGON_SOUP {
                        ImGui.Checkbox(imgui_label("Wireframe   ", it), *it.display_info.wireframe);
                    }

                    shift := make_vector3(mesh.world_from_model._14, mesh.world_from_model._24, mesh.world_from_model._34);
                    // ImGui.PushItemWidth(-1);
                    ImGui.DragFloat3(imgui_label("Shift", it), *shift.component, .05);
                    // ImGui.PopItemWidth();
                    mesh.world_from_model._14, mesh.world_from_model._24, mesh.world_from_model._34 = shift.x, shift.y, shift.z;
                } else {
                    for app.entities if get_mesh(it) && it.is_selected {
                        if it.fully_pathed_filename.count {
                            text := entity_fully_pathed_filename_with_generation_index(<<it);
                            ImGui.Text(text);
                        }
                    }

                    if ImGui.Button("Reload Selected Items", size=*V2_ZERO) {
                        reload_selected_entities();
                        ImGui.CloseCurrentPopup();
                    }

                    ImGui.SameLine();
                    if ImGui.Button("Clear Selection", size=*V2_ZERO) {
                        for app.entities if get_mesh(it) && it.is_selected {
                            it.is_selected = false;
                        }
                        ImGui.CloseCurrentPopup();
                    }
                }
            }
        }
    }

    {
        ImGui.Separator();

        it := *app.user_selection;

        // Toggle visibility checkbox
        visibility_toggled := checkbox_press_or_sweep_to_toggle(*it.display_info.visible, *it.display_info.visible_sweep_hovered, imgui_label("##Visible", it));
        Show_Tooltip("Visible");
        any_visibility_toggled = any_visibility_toggled || visibility_toggled;

        // Remove button
        ImGui.SameLine();
        if ImGui.Button(imgui_label("Clear ", it), size=*V2_ZERO) {
            deinit(it);
        }

        // Color picker
        ImGui.SameLine();
        ImGui.ColorEdit4(imgui_label("##color", it), *it.display_info.color.component, ImGui.ColorEditFlags.NoInputs);

        ImGui.SameLine();
        ImGui.Text("User selection");
        Show_Tooltip("RMB: Show context menu\nLMB: Focus item\nCtrl+LMB in scene: add/remove closest vertex\nEnable visibility to use");
        if ImGui.IsItemClicked() {
            fit_on_screen(it);
        }
        was_flash_hovered := it.display_info.flash_hovered;
        if ImGui.IsItemHovered() {
            it.display_info.flash_hovered = true;
            it.display_info.flash_wave_dt += io().DeltaTime;
        } else if was_flash_hovered {
            it.display_info.flash_hovered = false;
            it.display_info.flash_wave_dt = 0;
        }

        if ImGui.BeginPopupContextItem(imgui_label("##context_menu", it)) {
            defer ImGui.EndPopup();

                ImGui.Text(to_c_string(tprint("#points = %", it.mesh.positions.count)));

                maybe_update_render_info(*it.render_info, *it.mesh);
                aabb := it.render_info.bounding_aabb;
                ImGui.Text(to_c_string(tprint("AABB [%, %, %], [%, %, %]",
                                              aabb.min_point.x, aabb.min_point.y, aabb.min_point.z,
                                              aabb.max_point.x, aabb.max_point.y, aabb.max_point.z)));

                ImGui.Separator();

                // combo_box("", *it.display_info.display_mode, type_info(type_of(it.display_info.display_mode)));
                // ImGui.SameLine();
                // ImGui.PushItemWidth(70);
                // ImGui.DragFloat(imgui_label("##Opacity", it), *it.display_info.color.w, v_speed=.005, v_min=0., v_max=1.);
                // ImGui.PopItemWidth();
                // Show_Tooltip("Opacity");

                vertex_label_style := *it.display_info.vertex_label_style;

                ImGui.Checkbox("Position labels", *vertex_label_style.show_position);
                ImGui.SameLine();
                ImGui.ColorEdit4("Label color", *vertex_label_style.label_color.component, ImGui.ColorEditFlags.NoInputs);
                point_size : s32 = xx vertex_label_style.point_size;
                ImGui.InputInt("Point size", *point_size, 2);
                vertex_label_style.point_size = xx clamp(point_size, 2, 6);

                trailing_width : s32 = xx vertex_label_style.format_float.trailing_width;
                ImGui.InputInt("Float decimals", *trailing_width);


                vertex_label_style.format_float.trailing_width = clamp(trailing_width, 0, 12);
                Show_Tooltip("Number of digits following the decimal point");
                combo_box("Float format", *vertex_label_style.format_float.mode, type_info(FormatFloat.Mode));
                ImGui.DragFloat("Label scale", *vertex_label_style.label_scale, .005, .2, 1., display_format="%.3f");

                ImGui.Checkbox("Dynamically show the closest vertex result at cursor", *app.user_selection_cursor_text_shown);
                Show_Tooltip("Format is '#E,I {X,Y,Z}'\n X,Y,Z are the coordinates of the closest vertex\n E is entity index to which it belongs\n I is the vertex index within the entity");
                ImGui.DragFloat("Cursor text scale", *app.user_selection_cursor_text_scale, .005, .2, 1., display_format="%.3f");
                ImGui.InputInt("Max #points for selectable entities", xx *app.user_selection_max_point_count_for_selectable_entity);
        }
    }

    if app.settings.fit_to_screen_on_visibility_toggle && any_visibility_toggled {
        fit_on_screen();
    }

    if entity_to_remove >= 0 && entity_to_remove < entities.count {
        deinit(entities[entity_to_remove]);
        free(entities[entity_to_remove]);
        array_ordered_remove_by_index(*entities, entity_to_remove);
    }
}

show_camera_controls :: () {
    window_pos := make_vector2(ImGui.GetIO().DisplaySize.x - WINDOW_BORDER_UI_OFFSET.x, WINDOW_BORDER_UI_OFFSET.y);
    window_pivot := make_vector2(1, 0);

    using ImGui.WindowFlags;

    ImGui.SetNextWindowPos(*window_pos, .Always, *window_pivot);
    // SetNextWindowSize(ImVec2(400,400), ImGuiCond_FirstUseEver);
    // ImGui.SetNextWindowSize(*ImVec2.{150., 0.});
    ImGui.SetNextWindowContentSize(*ImVec2.{110., 0.});
    // ImGui.SetNextWindowBgAlpha(.3);
    ImGui.Begin("Camera shortcuts", flags = NoTitleBar | AlwaysAutoResize | NoMove /*| NoNav*/);
    defer ImGui.End();

    X_AXIS :: Vector3.{1, 0, 0};
    Y_AXIS :: Vector3.{0, 1, 0};
    Z_AXIS :: Vector3.{0, 0, 1};

    keep_up := app.settings.camera_controls_keep_up_when_setting_look_along;

    // @Incomplete Interpolate the motion

    ImGui.Columns(3, border=false);
    if ImGui.Button("+X ", size=*V2_ZERO) {
        set_look_direction(direction=X_AXIS, up=ifx keep_up then app.camera.up_direction else Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("+Y ", size=*V2_ZERO) {
        set_look_direction(direction=Y_AXIS, up=ifx keep_up then app.camera.up_direction else Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("+Z ", size=*V2_ZERO) {
        set_look_direction(direction=Z_AXIS, up=ifx keep_up then app.camera.up_direction else Y_AXIS);
    }
    ImGui.NextColumn();

    if ImGui.Button("-X ", size=*V2_ZERO) {
        set_look_direction(direction=-X_AXIS, up=ifx keep_up then app.camera.up_direction else Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("-Y ", size=*V2_ZERO) {
        set_look_direction(direction=-Y_AXIS, up=ifx keep_up then app.camera.up_direction else Z_AXIS);
    }
    ImGui.NextColumn();
    if ImGui.Button("-Z ", size=*V2_ZERO) {
        set_look_direction(direction=-Z_AXIS, up=ifx keep_up then app.camera.up_direction else Y_AXIS);
    }
    ImGui.NextColumn();

    // @Volatile: button text should be kept in sync with keymap!
    right_label, left_label, amount := "<< ", " >>", 15.;
    if app.modifier_flags.shift_pressed {
        right_label, left_label, amount = "<<<", ">>>", 45.;
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

    ImGui.PushItemWidth(100);
    combo_box("", *app.camera.rotation_axis, type_info(type_of(app.camera.rotation_axis)));
    Show_Tooltip("Camera Rotation Axis");

    if app.camera.look_position != Vector3.{0, 0, 0} {
        if ImGui.Button(" Reset Orbit ", size=*V2_ZERO) {
            look_direction := current_look_direction();
            app.camera.look_position = .{0, 0, 0};
            app.camera.eye_position = app.camera.look_position - look_direction;
        }
    }

    // @Incomplete add perspective/orthographic toggle
    // @Incomplete add button to reset look position
}

show_help_ui :: ()
{
    if !app.show_help_ui return;

    window_pos := make_vector2(ImGui.GetIO().DisplaySize.x - WINDOW_BORDER_UI_OFFSET.x, WINDOW_BORDER_UI_OFFSET.y);
    window_pivot := make_vector2(1, 0);

    ImGui.SetNextWindowPos(pos=*window_pos, pivot=*window_pivot);
    ImGui.Begin("##show_help_ui", flags = ImGui.WindowFlags.NoTitleBar | .AlwaysAutoResize | .NoMove /*| .NoNav*/);
    defer ImGui.End();

    ImGui.Text("Use MMB to pan the camera");
    ImGui.Text("Use RMB to rotate the camera (Alt to slow down, Shift to change axis)");
    ImGui.Text("Use scroll to zoom the camera (Alt to slow down, Shift to speed up)");
    ImGui.Text("Click a filename with LMB to focus an item");
    ImGui.Text("Click a filename with RMB to access a per-item context menu");
    ImGui.NewLine();

    ImGui.Separator();
    ImGui.Columns(2);
    ImGui.SetColumnWidth(-1, 80);
    ImGui.Text("Binding");
    ImGui.NextColumn();
    // ImGui.SetColumnWidth(-1, 250);
    ImGui.Text("Function");
    ImGui.NextColumn();
    ImGui.Separator();

    for app.keymap_keydown.mappings {
        Push_Temporary();
        ImGui.Text(to_c_string(tprint("%", to_string(it))));
        ImGui.NextColumn();
        ImGui.Text(to_c_string(tprint("%", app.keymap_keydown.procs[it.proc_info_index].name)));
        ImGui.NextColumn();
    }

    for app.keymap.mappings {
        Push_Temporary();
        ImGui.Text(to_c_string(tprint("%", to_string(it))));
        ImGui.NextColumn();
        ImGui.Text(to_c_string(tprint("%", app.keymap.procs[it.proc_info_index].name)));
        ImGui.NextColumn();
    }

    ImGui.Columns(1);
    ImGui.NewLine();
    ImGui.Text("Note: S=Shift, C=Ctrl, M=Alt");

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

// Toggle visibility if the checkbox was pressed or if we swept over it with the LMB down
checkbox_press_or_sweep_to_toggle :: (state : *bool, hovered : *bool, label : *u8) -> bool
{

    state_copy := <<state;
    checkbox_pressed := ImGui.Checkbox(label, *state_copy);

    previous_frame_hovered := <<hovered;
    current_frame_hovered := ImGui.IsItemHovered(.RectOnly);

    swept_into := !previous_frame_hovered && current_frame_hovered;
    left_mouse_button_down := io().MouseDown[0];

    clicked := ImGui.IsMouseClicked(0) && current_frame_hovered;
    pressed := checkbox_pressed && !current_frame_hovered;
    swept   := swept_into && left_mouse_button_down;

    changed := false;
    if (clicked || pressed || swept) {
        <<state = !<<state;
        changed = true;
    }

    <<hovered = current_frame_hovered;
    return changed;
}

Show_Tooltip :: (description : string) #expand {
    if (ImGui.IsItemHovered()) {
        ImGui.BeginTooltip();
        // ImGui.PushTextWrapPos(450);
        ImGui.TextUnformatted(description);
        // ImGui.PopTextWrapPos();
        ImGui.EndTooltip();
    }
}
