#scope_file
geom :: #import "geometry";

#scope_export

Camera :: struct {
    // Data to transfrom from world to view coordinates
    eye_position :   Vector3; // world
    look_position : Vector3;
    up_direction :   Vector3;

    ProjectionType :: enum u8 {ORTHOGRAPHIC; PERSPECTIVE;};
    projection_type := ProjectionType.ORTHOGRAPHIC;

    // Data for orthographic projection
    left:   float;
    right:  float;
    bottom: float;
    top:    float;

    // Data for perspective projection
    fov_vertical_radians : float;
    aspect_ratio_horizontal_over_vertical : float;

    near : float;
    far :  float;
}

camera : Camera;

init_camera :: () {
    camera.aspect_ratio_horizontal_over_vertical = cast(float) INITIAL_WINDOW_WIDTH / cast(float) INITIAL_WINDOW_HEIGHT;

    camera.eye_position = make_vector3(0, 0, 200);
    camera.look_position = make_vector3(0, 0, 0);
    camera.up_direction = make_vector3(0, 1, 0);

    camera.projection_type = .ORTHOGRAPHIC;

    camera.top = 70;
    camera.bottom = -camera.top;
    camera.right = camera.top * camera.aspect_ratio_horizontal_over_vertical;
    camera.left = -camera.right;

    camera.fov_vertical_radians = 2 * atan2(camera.top, camera.eye_position.z);

    camera.near = 0.1;
    camera.far = 400;
}

update_camera :: (camera : *Camera, delta_time : float, mouse : *MouseState) {
    k_max_drag_angle_degrees : float : 20; // @Unused

    camera.aspect_ratio_horizontal_over_vertical = cast(float) current_window_width / cast(float) current_window_height;
    aspect := camera.aspect_ratio_horizontal_over_vertical;
    camera.fov_vertical_radians = 2 * atan2(camera.top, camera.eye_position.z);

    // Pan with left down
    if mouse.left_down {
        // Convert mouse velocity from pixels/frame into view coords/frame
        ndc_per_frame : Vector2;
        ndc_per_frame.x = (2 * mouse.velocity_px.x) / cast(float)current_window_width * (camera.right - camera.left) / 2;
        ndc_per_frame.y = (2 * mouse.velocity_px.y) / cast(float)current_window_height * (camera.top - camera.bottom) / 2;

        increment : Vector2 = ndc_per_frame;
        increment.x = dot_product(ndc_per_frame, rotate(unit_vector(camera.up_direction.xy), -TAU/4)); // @Cleanup: use projection/rejection functions here
        increment.y = dot_product(ndc_per_frame, unit_vector(camera.up_direction.xy));

        camera.eye_position.x -= increment.x;
        camera.eye_position.y += increment.y;
        camera.look_position.x -= increment.x;
        camera.look_position.y += increment.y;
    }

    // Rotate with middle down
    if mouse.middle_down {
        // @FIXME: This screws up panning
        camera.up_direction.xy = rotate(camera.up_direction.xy, 0.01 * mouse.velocity_px.y);
    }

    // Zoom with right down or scrolling
    increment : float = 0;
    if mouse.right_down {
        increment = xx -0.03 * mouse.velocity_px.y;
    } else {
        increment = -mouse.wheel;
    }
    camera.top += increment;
    camera.bottom -= increment;
    camera.right += aspect * increment;
    camera.left -= aspect * increment;

    camera.top = max(camera.top, 0.1);
    camera.bottom = min(camera.bottom, -0.1);
    camera.right = max(camera.right, aspect * 0.1);
    camera.left = min(camera.left, -aspect * 0.1);;

    // print("update_camera: %\n", << camera);
}

// update_to_fit_on_screen :: (camera : *Camera, bbox : *$T/geom.AxisBox) { // @CompilerBug?
update_to_fit_on_screen :: (using camera : *Camera, world_box : *geom.AxisBox2) {
    if geom.is_empty(world_box) {
        return;
    }

    center := geom.center_point(world_box);
    eye_position.xy = center;
    look_position.xy = center;
    up_direction = make_vector3(0, 1, 0);

    view_from_world := make_look_at_matrix(camera);
    view_min := view_from_world * make_vector4(world_box.min_point.x, world_box.min_point.y, 0, 1);
    view_max := view_from_world * make_vector4(world_box.max_point.x, world_box.max_point.y, 0, 1);

    aspect := aspect_ratio_horizontal_over_vertical;
    extents := geom.extents(world_box);
    scale := (extents.y / 2) / top;
    if scale * right < (extents.x / 2) {
        scale = (extents.x / 2) / right;
    }

    camera.top *= scale;
    camera.bottom *= scale;
    camera.right *= scale;
    camera.left *= scale;

    // @TODO pick these numbers so details at 5um are clearly visible e.g., fill up whole screen?
    camera.top = max(camera.top, 0.1);
    camera.bottom = min(camera.bottom, -0.1);
    camera.right = max(camera.right, aspect * 0.1);
    camera.left = min(camera.left, -aspect * 0.1);;
}

// @Cleanup: use Math.make_look_at_matrix here
make_look_at_matrix :: (using camera : *Camera) -> Matrix4 #must {
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

make_orthographic_projection_matrix :: (using camera : *Camera) -> Matrix4 #must {
    return orthographic_projection_matrix(left, right, bottom, top, near, far);
}
