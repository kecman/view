// :UserConfig hotload changes to this file
User_Settings :: struct {
    fit_to_screen_on_visibility_toggle := false;
    fit_to_screen_on_file_drop_event   := true;

    camera_controls_keep_up_when_setting_look_along := true;

    camera_zoom_scrolling_follows_cursor := true;
    camera_zoom_dragging_follows_cursor  := false;
    camera_zoom_scrolling_ratio          := .8;
    camera_zoom_dragging_ratio           := .8;
    camera_zoom_min_screen_filling_length_mm := .0001; // .1um
    camera_zoom_max_screen_filling_length_factor := 4.; // multiplies a visible scene bounding sphere radius
    camera_zoom_max_limited_by_scene_bounding_sphere := true;

    duplicate_file_behaviour := Duplicate_File_Behaviour.APPEND;
}

Duplicate_File_Behaviour :: enum u8 #specified {
    APPEND :: 0;
    IGNORE :: 1;
    // OVERWRITE :: 2;
    // ASK :: 3;
}

clamp_user_settings :: ()
{
    app.settings.camera_zoom_dragging_ratio               = clamp(app.settings.camera_zoom_dragging_ratio,
                                                                  .3, .99);
    app.settings.camera_zoom_scrolling_ratio              = clamp(app.settings.camera_zoom_scrolling_ratio,
                                                                  .3, .99);
    app.settings.camera_zoom_min_screen_filling_length_mm = clamp(app.settings.camera_zoom_min_screen_filling_length_mm,
                                                                  .00001, app.camera.scene_bounding_sphere.radius / 2);
}