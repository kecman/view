Camera :: struct {
    // Data to transfrom from world to view coordinates
    eye_position :   Vector3; // world
    look_position : Vector3;
    up_direction :   Vector3;

    ProjectionType :: enum u8 {ORTHOGRAPHIC; PERSPECTIVE;};
    projection_type := ProjectionType.ORTHOGRAPHIC;

    // Data for orthographic projection
    Orthographic :: struct {
        left:   float;
        right:  float;
        bottom: float;
        top:    float;
    }
    orthographic : Orthographic;

    // Data for perspective projection
    Persepective :: struct {
        fov_vertical_radians : float;
        aspect_ratio_horizontal_over_vertical : float;
    }
    perspective : Persepective;

    near : float;
    far :  float;
}

camera : Camera;

init_camera :: () {
    camera.perspective.aspect_ratio_horizontal_over_vertical = cast(float) INITIAL_WINDOW_WIDTH / cast(float) INITIAL_WINDOW_HEIGHT;

    camera.eye_position = make_vector3(0, 0, 200);
    camera.look_position = make_vector3(0, 0, 0);
    camera.up_direction = make_vector3(0, 1, 0);

    camera.projection_type = .ORTHOGRAPHIC;

    camera.orthographic.top = 70;
    camera.orthographic.bottom = -camera.orthographic.top;
    camera.orthographic.right = camera.orthographic.top * camera.perspective.aspect_ratio_horizontal_over_vertical;
    camera.orthographic.left = -camera.orthographic.right;

    camera.perspective.fov_vertical_radians = 2 * atan2(camera.orthographic.top, camera.eye_position.z);

    camera.near = 0.1;
    camera.far = 400;
}

update_camera :: (camera : *Camera, delta_time : float, mouse : *MouseState) {
    camera_old := << camera;

    k_max_drag_angle_degrees : float : 20; // @Unused

    camera.perspective.aspect_ratio_horizontal_over_vertical = cast(float) current_window_width / cast(float) current_window_height;
    aspect := camera.perspective.aspect_ratio_horizontal_over_vertical;
    camera.perspective.fov_vertical_radians = 2 * atan2(camera.orthographic.top, camera.eye_position.z);

    // Pan with middle down
    if mouse.middle_down {
        // Convert mouse velocity from pixels/frame into NDC/frame @Unused
        ndc_per_frame : Vector2;
        ndc_per_frame.x = (2 * mouse.velocity_px.x) / cast(float)current_window_width;
        ndc_per_frame.y = (2 * mouse.velocity_px.y) / cast(float)current_window_height;

        camera.eye_position.x -= ndc_per_frame.x * (camera.orthographic.right - camera.orthographic.left) / 2;
        camera.eye_position.y += ndc_per_frame.y * (camera.orthographic.top - camera.orthographic.bottom) / 2;
        camera.look_position.x -= ndc_per_frame.x * (camera.orthographic.right - camera.orthographic.left) / 2;
        camera.look_position.y += ndc_per_frame.y * (camera.orthographic.top - camera.orthographic.bottom) / 2;
    }

    // Rotate about look direction with left down? Might be annoying
    if mouse.left_down {
        // @Incomplete
    }

    // Zoom with right down or scrolling
    // @FIXME not dollying since then we have stupid stuff to do with the clipping planes
    increment : float = 0;
    if mouse.right_down {
        increment = xx mouse.velocity_px.y;
    } else {
        increment = mouse.wheel;
    }
    camera.orthographic.top += increment;
    camera.orthographic.bottom -= increment;
    camera.orthographic.right += aspect * increment;
    camera.orthographic.left -= aspect * increment;

    camera.orthographic.top = max(camera.orthographic.top, 0.1);
    camera.orthographic.bottom = min(camera.orthographic.bottom, -0.1);
    camera.orthographic.right = max(camera.orthographic.right, aspect * 0.1);
    camera.orthographic.left = min(camera.orthographic.left, -aspect * 0.1);;

    print("update_camera: %\n", << camera);
}

// fit_to_screen :: (camera : *Camera, bbox : AxisBox2) {}

make_look_at_matrix :: (camera : *Camera) -> Matrix4 #must {
    // @Cleanup: use Math.make_look_at_matrix here
    return geom.make_look_at_matrix(camera.eye_position, camera.look_position, camera.up_direction);
}

make_orthographic_projection_matrix :: (camera : *Camera) -> Matrix4 #must {
    // @CompilerBug This funky combination of using is a bit suspicious
    // using camera;
    // using Orthographic;
    // return orthographic_projection_matrix(left, right, bottom, top, near, far);
    return orthographic_projection_matrix(camera.orthographic.left, camera.orthographic.right, camera.orthographic.bottom, camera.orthographic.top, camera.near, camera.far);
}

#scope_file
geom :: #import "Geom";
