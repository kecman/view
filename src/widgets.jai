// Eventually this will actually be a viewcube :)
// Interpolate the motion

render_viewcube :: () {
    if !app.show_viewcube_ui return;

    window_pos := make_vector2(ImGui.GetIO().DisplaySize.x - 10., 10.);
    window_pivot := make_vector2(1, 0);

    using ImGui.WindowFlags;

    ImGui.SetNextWindowPos(*window_pos, .Always, *window_pivot);
    // ImGui.SetNextWindowContentWidth(135.);
    // ImGui.SetNextWindowBgAlpha(.3);
    ImGui.Begin("Camera shortcuts", flags = NoTitleBar | AlwaysAutoResize | NoMove /*| NoNav*/);
    // ImGui.Text("Look Along");

    if ImGui.Button("+X ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.set_look_along_x();
    }
    ImGui.SameLine();
    if ImGui.Button("+Y ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.set_look_along_y();
    }
    ImGui.SameLine();
    if ImGui.Button("+Z ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.set_look_along_z();
    }

    if ImGui.Button("-X ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.set_look_along_x(false);
    }
    ImGui.SameLine();
    if ImGui.Button("-Y ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.set_look_along_y(false);
    }
    ImGui.SameLine();
    if ImGui.Button("-Z ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.set_look_along_z(false);
    }

    /*
    ImGui.Separator();
    if ImGui.Button(" << ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.rotate_45_deg_around_z(false);
    }
    ImGui.SameLine();
    if ImGui.Button("XYZ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.set_look_along_xyz();
    }
    ImGui.SameLine();
    if ImGui.Button(" >> ", size=*make_vector2(0,0)) {
        // sim_data_.camera3d_mover.rotate_45_deg_around_z();
    }

    if (ImGui.Button(sim_data_.get_camera3d().is_using_perspective() ? "orthographic " : "  perspective  ")) {
        sim_data_.get_camera3d().set_use_perspective(!sim_data_.get_camera3d().is_using_perspective());
    }

    if (!num::exactly_equal(sim_data_.camera3d_mover.get_origin(), num.vec3(0))
        && ImGui.Button("  reset origin  ")) {
        sim_data_.camera3d_mover.set_origin({0, 0, 0});
    }
    */

    ImGui.End();
}