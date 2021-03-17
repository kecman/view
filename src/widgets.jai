
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

    if ImGui.Button(" < ", size=*V2_ZERO) {
        // rotate_look_direction_around_up_direction(45);
        rotate_look_direction_around_look_along(45);
    }
    ImGui.SameLine();
    if ImGui.Button("XYZ", size=*V2_ZERO) {
        // Having up = Z_AXIS instead is actually kinda nice, hmm...
        up := normalize(cross(.{-1, 1, 0}, .{-1, -1, -1}));
        set_look_direction(direction=.{-1, -1, -1}, up=up);
    }
    ImGui.SameLine();
    if ImGui.Button(" > ", size=*V2_ZERO) {
        // rotate_look_direction_around_up_direction(-45);
        rotate_look_direction_around_look_along(-45);
    }

    if ImGui.Button(" Reset Focus ", size=*V2_ZERO) {
        app.camera.look_position = .{0, 0, 0};
    }

    // @Incomplete add perspective/orthographic toggle
    // @Incomplete add button to reset look position

    ImGui.End();
}