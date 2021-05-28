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

    // @TODO Default this to open
    if ImGui.TreeNode("%", "General Settings") {
        defer ImGui.TreePop();
        combo_box("Background", *app.background_style, type_info(Background_Style));
        if app.background_style == .SOLID_COLOR {
            ImGui.ColorEdit4("Background Color", *background_solid_color.component, ImGui.ColorEditFlags.NoInputs);
        }
        ImGui.Checkbox("World Axes", *world_axes.visible);

        ImGui.InputInt("Label limit", *app.label_limit);
        if app.label_limit > 2000 {
            color := ImVec4.{1., .4, .4, 1.};
            ImGui.TextColored(*color, "%s", "Warning: label limit > 2000 may be slow");
        }
    }

    // :UserConfig add a button to overwrite the user settings file with new defaults here?
    inspect("User Settings", *app.settings);
    clamp_user_settings();

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

    any_visibility_toggled := false;

    entity_to_remove := -1;
    for entities {
        // Remove button
        if ImGui.Button(imgui_label("Remove", it), size=*V2_ZERO) {
            entity_to_remove = it_index;
        }

        // Toggle visibility and set color
        ImGui.SameLine();
        visibility_toggled := checkbox_press_or_sweep_to_toggle(*it.display_info.visible, *it.display_info.visible_sweep_hovered, imgui_label("##Visible", it));
        Show_Tooltip("Visible");
        any_visibility_toggled = any_visibility_toggled || visibility_toggled;
        ImGui.SameLine();
        if it.display_info.display_mode == .NORMALS {
            ImGui.TextDisabled("NR.");
        } else {
            ImGui.ColorEdit4(imgui_label("##color", it), *it.display_info.color.component, ImGui.ColorEditFlags.NoInputs);
        }
        if ImGui.IsItemClicked(1) {
            cycle_display_mode(*it.display_info.display_mode);
        } else if ImGui.IsItemClicked(2) {
            if it.display_info.display_mode != .NORMALS {
                it.display_info.color = color_from_path(it.fully_pathed_filename);
            }
        }

        // Entity index used to refer to geometry in console or annotate the text following ther cursor when adding to the user selection
        if app.show_console_ui || app.user_selection.display_info.visible {
            ImGui.SameLine();
            label := to_c_string(tprint("#%", it_index));
            if it.mesh.positions.count <= app.user_selection_max_point_count_for_selectable_entity {
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
            if ImGui.Selectable(to_c_string(join(text, tprint("##%", it))), *it.is_selected, size=*V2_ZERO) { // @Leak? free the join'd string?
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
        was_hovered := it.is_hovered;
        it.is_hovered = ImGui.IsItemHovered();
        if ImGui.IsItemHovered() {
            it.display_info.flash_wave_dt += io().DeltaTime;
        } else if was_hovered {
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
                if it.fully_pathed_filename.count && ImGui.Button(imgui_label("Reload", it), size=*V2_ZERO) {
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
                ImGui.Text(to_c_string(tprint("Model space AABB [%, %, %]x[%, %, %]",
                                              aabb.min_point.x, aabb.min_point.y, aabb.min_point.z,
                                              aabb.max_point.x, aabb.max_point.y, aabb.max_point.z)));

                ImGui.Separator();

                set := display_info_ui(*it.display_info);
                if set.color_reset it.display_info.color = color_from_path(it.fully_pathed_filename);

                ImGui.Separator();
                shift := make_vector3(it.mesh.world_from_model._14, it.mesh.world_from_model._24, it.mesh.world_from_model._34);
                // ImGui.PushItemWidth(-1);
                ImGui.DragFloat3(imgui_label("Shift", it), *shift.component, .05);
                // ImGui.PopItemWidth();
                it.mesh.world_from_model._14, it.mesh.world_from_model._24, it.mesh.world_from_model._34 = shift.x, shift.y, shift.z;
            } else {
                for app.entities if it.is_selected {
                    if it.fully_pathed_filename.count {
                        text := entity_fully_pathed_filename_with_generation_index(<<it);
                        ImGui.Text(text);
                    }
                }

                if ImGui.Button("Reload Selected Items", size=*V2_ZERO) {
                    reload_entities();
                    ImGui.CloseCurrentPopup();
                }

                ImGui.SameLine();
                if ImGui.Button("Clear Selection", size=*V2_ZERO) {
                    for app.entities if it.is_selected {
                        it.is_selected = false;
                    }
                    ImGui.CloseCurrentPopup();
                }

                set := display_info_ui(*app.selection_display_info);

                for app.entities if it.is_selected {
                    other := *app.selection_display_info;
                    using it.display_info;

                    if set.vertex_label_style_is_set.show_position vertex_label_style.show_position = other.vertex_label_style.show_position;
                    if set.vertex_label_style_is_set.show_index    vertex_label_style.show_index    = other.vertex_label_style.show_index;
                    if set.vertex_label_style_is_set.format_float  vertex_label_style.format_float  = other.vertex_label_style.format_float;
                    if set.vertex_label_style_is_set.label_scale   vertex_label_style.label_scale   = other.vertex_label_style.label_scale;
                    if set.vertex_label_style_is_set.label_color   vertex_label_style.label_color   = other.vertex_label_style.label_color;

                    if set.visible         visible = other.visible;
                    if set.wireframe       wireframe = other.wireframe;
                    if set.color           color = other.color;
                    if set.color_reset     color = color_from_path(it.fully_pathed_filename);
                    if set.color_opacity   color.w = other.color.w;
                    if set.display_mode    display_mode = other.display_mode;
                    if set.normals_visible normals_visible = other.normals_visible;
                    if set.normals_color   normals_color = other.normals_color;
                    if set.normals_length  normals_length = other.normals_length;
                    if set.point_size      point_size = other.point_size;
                    if set.line_width      line_width = other.line_width;
                }
            }
        }
    }

    {
        ImGui.Separator();

        it := *app.user_selection;

        // Remove button
        if ImGui.Button(imgui_label("Clear ", it), size=*V2_ZERO) {
            deinit(it);
        }

        // Toggle visibility checkbox
        ImGui.SameLine();
        visibility_toggled := checkbox_press_or_sweep_to_toggle(*it.display_info.visible, *it.display_info.visible_sweep_hovered, imgui_label("##Visible", it));
        Show_Tooltip("User Selection Visible");
        any_visibility_toggled = any_visibility_toggled || visibility_toggled;
        ImGui.SameLine();
        ImGui.ColorEdit4(imgui_label("##color", it), *it.display_info.color.component, ImGui.ColorEditFlags.NoInputs);

        ImGui.SameLine();
        ImGui.Text("User selection");
        Show_Tooltip("RMB: Show context menu\nLMB: Focus item\nCtrl+LMB in scene: add/remove closest vertex\nEnable visibility to use");
        if ImGui.IsItemClicked() {
            fit_on_screen(it);
        }
        was_hovered := it.is_hovered;
        it.is_hovered = ImGui.IsItemHovered();
        if it.is_hovered {
            it.display_info.flash_wave_dt += io().DeltaTime;
        } else if was_hovered {
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
            ImGui.InputInt("Point size", *it.display_info.point_size);
            it.display_info.point_size = clamp(it.display_info.point_size, 2, 10);

            trailing_width : s32 = xx vertex_label_style.format_float.trailing_width;
            ImGui.InputInt("Float decimals", *trailing_width);
            vertex_label_style.format_float.trailing_width = clamp(trailing_width, 0, 12);
            Show_Tooltip("Number of digits following the decimal point");

            combo_box("Float format", *vertex_label_style.format_float.mode, type_info(FormatFloat.Mode));
            ImGui.DragFloat("Label scale", *vertex_label_style.label_scale, .005, .2, 1., display_format="%.3f");

            ImGui.Checkbox("Dynamic closest vertex result at cursor", *app.user_selection_cursor_text_shown);
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

show_help_ui :: () {
    if !app.show_help_ui return;

    window_pos := make_vector2(ImGui.GetIO().DisplaySize.x - WINDOW_BORDER_UI_OFFSET.x, WINDOW_BORDER_UI_OFFSET.y);
    window_pivot := make_vector2(1, 0);

    ImGui.SetNextWindowPos(pos=*window_pos, pivot=*window_pivot);
    ImGui.Begin("##show_help_ui", flags = ImGui.WindowFlags.NoTitleBar | .AlwaysAutoResize | .NoMove /*| .NoNav*/);
    defer ImGui.End();

    ImGui.Text("Use MMB in the viewport to pan the camera");
    ImGui.Text("Use RMB in the viewport to rotate the camera (Alt to slow down, Shift to change axis)");
    ImGui.Text("Use scroll in the view port to zoom the camera (Alt to slow down, Shift to speed up)");
    ImGui.Text("Use LMB on an item list filename to focus an item");
    ImGui.Text("Use RMB on an item list filename to access a per-item context menu");
    ImGui.Text("Use RMB on an item list color to cycle shading styles");
    ImGui.Text("Use MMB on an item list color to reset the color from the filename");
    ImGui.Text("\n");
    ImGui.Text("Note: The item list is in the top left (visible if there's at least one item loaded)");
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

// @Volatile keep this in sync with Vertex_Label_Style
Vertex_Label_Style_Is_Set :: struct {
    show_position : bool;
    show_index : bool;
    format_float : bool;
    label_scale : bool;
    label_color : bool;
}

// @Volatile keep this in sync with Display_Info
Display_Info_Is_Set :: struct {
    visible : bool;
    // visible_sweep_hovered : bool;
    // flash_wave_dt : bool;
    wireframe : bool;
    color : bool;
    display_mode : bool;
    normals_visible : bool;
    normals_color : bool;
    normals_length : bool;
    point_size : bool;
    line_width : bool;

    vertex_label_style_is_set : Vertex_Label_Style_Is_Set;

    color_reset : bool; // Not a member of Display_Info
    color_opacity : bool; // Not a member of Display_Info
}

display_info_ui :: (display_info : *Display_Info) -> Display_Info_Is_Set {

    set : Display_Info_Is_Set;

    ImGui.PushItemWidth(120);
    set.display_mode = combo_box("", *display_info.display_mode, type_info(type_of(display_info.display_mode)));
    ImGui.PopItemWidth();
    ImGui.SameLine();
    ImGui.PushItemWidth(70);
    set.color_opacity = ImGui.DragFloat(imgui_label("##Opacity", display_info), *display_info.color.w, v_speed=.005, v_min=0., v_max=1.);
    ImGui.PopItemWidth();
    Show_Tooltip("Opacity");

    // @Cleanup The following block is only really needed for .MESH and .POLYGON_SOUP types
    // @Incomplete Add AABB visiblity and color
    {
        set.normals_visible = ImGui.Checkbox(imgui_label("##normals_visible", display_info), *display_info.normals_visible);
        ImGui.SameLine();
        set.normals_color = ImGui.ColorEdit4(imgui_label("##normals_color", display_info), *display_info.normals_color.component, ImGui.ColorEditFlags.NoInputs);
        ImGui.SameLine();
        ImGui.Text("Normals   Visible|Color|Length:");
        ImGui.SameLine();
        ImGui.PushItemWidth(70);
        set.normals_length = ImGui.DragFloat(imgui_label("##normals_length", display_info), *display_info.normals_length, .05);
        ImGui.PopItemWidth();

        set.wireframe = ImGui.Checkbox(imgui_label("##wireframe_visible", display_info), *display_info.wireframe);
        ImGui.SameLine();
        // @FIXME @Incomplete wireframe_color
        set.color = ImGui.ColorEdit4(imgui_label("##wireframe_color", display_info), *display_info.color.component, ImGui.ColorEditFlags.NoInputs);
        ImGui.SameLine();
        ImGui.Text("Wireframe Visible|Color");

        set.visible = ImGui.Checkbox(imgui_label("##surface_visible", display_info), *display_info.visible);
        ImGui.SameLine();
        set.color = ImGui.ColorEdit4(imgui_label("##surface_color", display_info), *display_info.color.component, ImGui.ColorEditFlags.NoInputs);
        ImGui.SameLine();
        ImGui.Text("Surface   Visible|Color");
        ImGui.SameLine();
        set.color_reset = ImGui.Button(imgui_label("Color by filename##surface_color_reset", display_info), size=*V2_ZERO);

        ImGui.PushItemWidth(120);
        set.point_size = ImGui.InputInt("Point size", *display_info.point_size);
        display_info.point_size = clamp(display_info.point_size, 2, 10);
        set.line_width = ImGui.InputInt("Line width", *display_info.line_width);
        display_info.line_width = clamp(display_info.line_width, 1, 10);
        ImGui.PopItemWidth();
    }

    if ImGui.TreeNode("%", "Label Settings") {
        defer ImGui.TreePop();
        using display_info;

        // ImGui.Unindent(ImGui.GetTreeNodeToLabelSpacing());
        // defer ImGui.Indent(ImGui.GetTreeNodeToLabelSpacing());

        set.vertex_label_style_is_set.show_index = ImGui.Checkbox("Index labels", *vertex_label_style.show_index);
        ImGui.SameLine();
        set.vertex_label_style_is_set.show_position = ImGui.Checkbox("Position labels", *vertex_label_style.show_position);

        trailing_width : s32 = xx vertex_label_style.format_float.trailing_width;
        set.vertex_label_style_is_set.format_float |= ImGui.InputInt("Float decimals", *trailing_width);
        vertex_label_style.format_float.trailing_width = clamp(trailing_width, 0, 12);
        Show_Tooltip("Number of digits following the decimal point");

        set.vertex_label_style_is_set.format_float = combo_box("Float format", *vertex_label_style.format_float.mode, type_info(FormatFloat.Mode));
        set.vertex_label_style_is_set.label_scale  = ImGui.DragFloat("Label scale", *vertex_label_style.label_scale, .005, .2, 1., display_format="%.3f");
        set.vertex_label_style_is_set.label_color  = ImGui.ColorEdit4("Label color", *vertex_label_style.label_color.component, ImGui.ColorEditFlags.NoInputs);
    }

    return set;
}

imgui_label :: (label : string, ptr : *void) -> *u8 {
    Push_Temporary();
    return to_c_string(concatenate(label, tprint("##%", ptr)));
}

// Combo box to select display mode enum value
combo_box :: (label : string, data: *void, info_enum: *Type_Info_Enum) -> bool {
    changed := false;
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
                changed = true;
            }
            if is_selected ImGui.SetItemDefaultFocus();
        }

        ImGui.EndCombo();
    }
    return changed;
}

// Toggle visibility if the checkbox was pressed or if we swept over it with the LMB down
checkbox_press_or_sweep_to_toggle :: (state : *bool, hovered : *bool, label : *u8) -> bool {

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
