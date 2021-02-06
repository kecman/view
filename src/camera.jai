Camera :: struct {
    // Data to transfrom from world to view coordinates
    eye_position :  Vector3; // world
    look_position : Vector3;
    up_direction :  Vector3;

    ProjectionType :: enum u8 {
        ORTHOGRAPHIC;
        PERSPECTIVE;
    }

    projection_type := ProjectionType.ORTHOGRAPHIC;

    // Data for orthographic projection
    left:   float;
    right:  float;
    bottom: float;
    top:    float;

    // Data for perspective projection
    fov_vertical_radians : float;

    near : float;
    far :  float;
}

init_camera :: () {
    camera := *app.camera;

    // These define the camera coordinate system
    camera.eye_position = .{0, 0, 200};
    camera.look_position = .{0, 0, 0}; // arcball pivot
    camera.up_direction = .{0, 1, 0};

    camera.projection_type = .ORTHOGRAPHIC;

    camera.top = 70;
    camera.bottom = -camera.top;
    camera.right = camera.top * current_window_aspect_ratio_width_over_height();
    camera.left = -camera.right;

    camera.fov_vertical_radians = 2 * atan2(camera.top, camera.eye_position.z);

    camera.near = 0.1;
    camera.far = 400;
}

// @Cleanup: only do ONE operation using else if's
update_camera :: (delta_time : float) {
    camera := *app.camera;

    if ImGui.IsMouseClicked(0) {
        mouse_down_pos = io().MousePos;
        camera_at_mouse_down = app.camera;
    }

    if io().WantCaptureMouse || (io().MouseDelta.x == 0 && io().MouseDelta.y == 0) {
        return; // Mouse delta is zero when current or previous mouse positions were invalid
    }

    camera.fov_vertical_radians = 2 * atan2(camera.top, camera.eye_position.z);

    world_from_projection := inverse(make_projection_from_world(<<camera));

    // Pan with middle down.
    if io_mouse_middle_down() {

        get_pan_position :: (mouse_position_px : Vector2, world_from_projection : Matrix4, camera : Camera) -> Vector3 {
            plane := make_hyperplane3(unit_vector(camera.eye_position - camera.look_position), camera.look_position);
            line : Line3 = ---;
            line.origin = (world_from_projection * make_vector4(to_ndc(mouse_position_px), -1, 1)).xyz;
            line.direction = -plane.normal;

            intersect_count, intersect_t := find_intersect_line3_plane3(line, plane);
            assert(intersect_count == 1, "Expected 1 intersection, got %", intersect_count);
            assert(intersect_t >= 0, "Expected intersection in front of near plane with t >= 0, got t = %", intersect_t);
            return to_point(line, intersect_t);
        }

        // Shoot ray through pixel along the look vector to hit a plane through the look position with the same normal
        curr_pan_point := get_pan_position(io().MousePos, world_from_projection, <<camera);
        prev_pan_point := get_pan_position(io().MousePos - io().MouseDelta, world_from_projection, <<camera);
        increment := -(curr_pan_point - prev_pan_point) / 2; // @Cleanup WHY this divide by 2, there is probably a bug elsewhere... ?

        camera.eye_position += increment;
        camera.look_position += increment;
    }

    // Orbit about the look position using left button
    if ImGui.IsMouseDragging(0, 0.) {

        world_from_projection_at_mouse_down := inverse(make_projection_from_world(camera_at_mouse_down));

        prev_arcball_vector := arcball_vector(mouse_down_pos);
        curr_arcball_vector := arcball_vector(io().MousePos);

        arcball_axis4_ndc := make_vector4(cross_product(curr_arcball_vector, prev_arcball_vector), 0);
        arcball_axis_world := (world_from_projection_at_mouse_down * arcball_axis4_ndc).xyz;
        arcball_angle := angle(curr_arcball_vector, prev_arcball_vector);

        // @Cleanup fishy negative sign and rotation speed multiplier should be chosen so screen top/bottom or left/right rotates the scene by tau or tau/2 respectively.
        q : Quaternion = ---;
        set_from_axis_and_angle(*q, arcball_axis_world, -arcball_angle);

        look_to_eye := rotate(camera_at_mouse_down.eye_position - camera_at_mouse_down.look_position, q);

        #if false {
            debug_vector :: (vector_world : Vector3, color : Vector4) {
                debug_mesh_ps := make_axis_arrow(20);
                defer deinit(debug_mesh_ps);

                par_shapes_rotate(debug_mesh_ps, angle(Vector3.{0,0,1}, unit_vector(vector_world)), unit_vector(cross_product(Vector3.{0,0,1}, unit_vector(vector_world))));
                par_shapes_translate(debug_mesh_ps, camera.look_position);

                debug_mesh := to_Mesh(debug_mesh_ps);
                defer deinit(*debug_mesh);
                buffer_mesh(*debug_mesh);
                debug_mesh.wireframe = true;
                debug_mesh.color = color;
                render_mesh(debug_mesh, .{point_size=0, line_width=1});
            }

            debug_vector((world_from_projection * make_vector4(prev_arcball_vector, 0)).xyz, .{1., .5, .5, 1.});
            debug_vector((world_from_projection * make_vector4(curr_arcball_vector, 0)).xyz, .{.5, 1., .5, 1.});

            debug_vector(arcball_axis_world, .{0., 0., 0., 1.});
            debug_vector(look_to_eye, .{1., 1., 1., 1.});
            debug_vector(rotate(camera_at_mouse_down.up_direction, q), .{1., 1., 1., 1.});
            debug_vector(camera_at_mouse_down.eye_position - camera_at_mouse_down.look_position, .{1., 1., 0., 1.});
            debug_vector(camera_at_mouse_down.up_direction, .{1., 1., 0., 1.});
        }

        camera.eye_position = camera_at_mouse_down.look_position + look_to_eye;
        camera.up_direction = rotate(camera_at_mouse_down.up_direction, q);
    }

    // Zoom with right down or scrolling
    {
        increment : float = 0;
        if io_mouse_right_down() {
            increment = xx -0.03 * io().MouseDelta.y;
        } else {
            increment = -io().MouseWheel;
        }
        camera.top += increment;
        camera.bottom -= increment;
        camera.right += current_window_aspect_ratio_width_over_height() * increment;
        camera.left -= current_window_aspect_ratio_width_over_height() * increment;

        camera.top = max(camera.top, 0.1);
        camera.bottom = min(camera.bottom, -0.1);
        camera.right = max(camera.right, current_window_aspect_ratio_width_over_height() * 0.1);
        camera.left = min(camera.left, -current_window_aspect_ratio_width_over_height() * 0.1);;
    }

    // print("update_camera: %\n", camera);
}

// @Cleanup use Math.make_look_at_matrix here
make_look_at_matrix :: (using camera : Camera) -> Matrix4 #must {
    f := normalize_or_z_axis(look_position - eye_position);
    s := normalize_or_z_axis(cross(f, up_direction));
    u := cross(s, f);

    m := matrix4_identity();

    // See glm::lookAtRH, but using row-major
    m.coef[0][0] =  s.x;
    m.coef[0][1] =  s.y;
    m.coef[0][2] =  s.z;
    m.coef[1][0] =  u.x;
    m.coef[1][1] =  u.y;
    m.coef[1][2] =  u.z;
    m.coef[2][0] = -f.x;
    m.coef[2][1] = -f.y;
    m.coef[2][2] = -f.z;
    m.coef[0][3] = -dot(s, eye_position);
    m.coef[1][3] = -dot(u, eye_position);
    m.coef[2][3] =  dot(f, eye_position);

    return m;
}

make_orthographic_projection_matrix :: (using camera : Camera) -> Matrix4 #must {
    return orthographic_projection_matrix(left, right, bottom, top, near, far);
}

make_projection_from_world :: (using camera : Camera) -> Matrix4 #must {
    if #complete projection_type == {
        case .ORTHOGRAPHIC;
            view_from_world := make_look_at_matrix(camera);
            projection_from_view := make_orthographic_projection_matrix(camera);
            return projection_from_view * view_from_world;
        case .PERSPECTIVE;
            assert(false);
            return matrix4_identity();
    }
}

io :: () -> *ImGui.IO {return ImGui.GetIO(); }
io_mouse_left_down :: () -> bool { return io().MouseDown[0]; }
io_mouse_right_down :: () -> bool { return io().MouseDown[1]; }
io_mouse_middle_down :: () -> bool { return io().MouseDown[2]; }

#scope_file

arcball_vector :: (mouse_position_px : Vector2) -> Vector3
{
    arcball_center_px := make_vector2(app.current_window_width / 2., app.current_window_height / 2.);
    arcball_radius_px := min(app.current_window_height, app.current_window_width) / 2.; // allows room on left/right for rotation look direction
    // arcball_radius_px := length(make_vector2(xx app.current_window_height, xx app.current_window_width) / 2); // only room to rotate on sphere

    using result := make_vector3((mouse_position_px - arcball_center_px) / arcball_radius_px, 0);
    y *= -1; // Since y_px increases from the top of the screen to the bottom
    d2 := x*x + y*y;
    if d2 <= 1. {
        z = -sqrt(1. - d2); // In NDC units Z = -1 is closest to the camera
    } else {
        result = normalize(result);
    }
    return result;
}

// Return normalised device coordinates corresponding to the pixel position.
to_ndc :: (position_px : Vector2) -> Vector2
{
    using position_ndc : Vector2 = ---;
    x = 2 * (position_px.x / cast(float)app.current_window_width) - 1;
    y = 2 * (position_px.y / cast(float)app.current_window_height) - 1;
    y *= -1; // (-1,-1) => bottom-left of screen, (+1,+1) => top-right of screen

    // print("NDC : %", position_ndc);
    assert(x >= -1 && x <= 1, "Expected NDC x coordinates to be in range [-1,+1], got %", x);
    assert(y >= -1 && y <= 1, "Expected NDC y coordinates to be in range [-1,+1], got %", y);

    return position_ndc;
}

camera_at_mouse_down : Camera;
mouse_down_pos : Vector2; // @Cleanup: replace this state with ImGui: use GetMouseDragDelta

geom :: #import "geometry";
#load "numeric.jai";
#load "geometric_operations.jai";