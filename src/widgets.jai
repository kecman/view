
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
        set_look_along_direction(direction=X_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("+Y ", size=*V2_ZERO) {
        set_look_along_direction(direction=Y_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("+Z ", size=*V2_ZERO) {
        set_look_along_direction(direction=Z_AXIS, up=Y_AXIS);
    }

    if ImGui.Button("-X ", size=*V2_ZERO) {
        set_look_along_direction(direction=-X_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("-Y ", size=*V2_ZERO) {
        set_look_along_direction(direction=-Y_AXIS, up=Z_AXIS);
    }
    ImGui.SameLine();
    if ImGui.Button("-Z ", size=*V2_ZERO) {
        set_look_along_direction(direction=-Z_AXIS, up=Y_AXIS);
    }

    ImGui.Separator();

    if ImGui.Button(" < ", size=*V2_ZERO) {
        rotate_look_along_around_up(45);
    }
    ImGui.SameLine();
    if ImGui.Button("XYZ", size=*V2_ZERO) {
        up := normalize(cross(.{-1, 1, 0}, .{-1, -1, -1}));
        set_look_along_direction(direction=.{-1, -1, -1}, up=up);
    }
    ImGui.SameLine();
    if ImGui.Button(" > ", size=*V2_ZERO) {
        rotate_look_along_around_up(-45);
    }

    // @Incomplete add perspective/orthographic toggle
    // @Incomplete add button to reset look position

    ImGui.End();
}