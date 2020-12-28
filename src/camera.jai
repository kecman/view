camera : Camera;

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
    aspect_ratio_horizontal_over_vertical := cast(float) INITIAL_WINDOW_WIDTH / cast(float) INITIAL_WINDOW_HEIGHT;

    near : float;
    far :  float;
}

init_camera :: () {
    camera.aspect_ratio_horizontal_over_vertical = cast(float) INITIAL_WINDOW_WIDTH / cast(float) INITIAL_WINDOW_HEIGHT;

    // These define the camera coordinate system
    camera.eye_position = .{0, 0, 200};
    camera.look_position = .{0, 0, 0}; // arcball pivot
    camera.up_direction = .{0, 1, 0};

    camera.projection_type = .ORTHOGRAPHIC;

    camera.top = 70;
    camera.bottom = -camera.top;
    camera.right = camera.top * camera.aspect_ratio_horizontal_over_vertical;
    camera.left = -camera.right;

    camera.fov_vertical_radians = 2 * atan2(camera.top, camera.eye_position.z);

    camera.near = 0.1;
    camera.far = 400;
}

update_camera :: (camera : *Camera, delta_time : float, mouse : MouseState) {

    camera.aspect_ratio_horizontal_over_vertical = cast(float) current_window_width / cast(float) current_window_height;
    aspect := camera.aspect_ratio_horizontal_over_vertical;
    camera.fov_vertical_radians = 2 * atan2(camera.top, camera.eye_position.z);

    view_from_world := make_look_at_matrix(camera);
    projection_from_view := make_orthographic_projection_matrix(camera);
    world_from_projection := inverse(projection_from_view * view_from_world);

    // Pan with middle down.
    if mouse.middle_down {

        get_pan_position :: (mouse_position_px : Vector2, transform : Matrix4, camera : Camera) -> Vector3 {
            plane := make_hyperplane3(unit_vector(camera.eye_position - camera.look_position), camera.look_position);
            line : Line3 = ---;
            line.origin = (transform * make_vector4(make_vector3(to_ndc(mouse_position_px), -1), 1)).xyz;
            line.direction = -plane.normal;

            intersect_count, intersect_t := find_intersect_line3_plane3(line, plane);
            assert(intersect_count == 1, "Expected 1 intersection, got %", intersect_count);
            assert(intersect_t >= 0, "Expected intersection in front of near plane with t >= 0, got t = %", intersect_t);
            return to_point(line, intersect_t);
        }

        // Shoot ray through pixel along the look vector to hit a plane through the look position with the same normal
        curr_pan_point := get_pan_position(mouse.position_px, world_from_projection, <<camera);
        prev_pan_point := get_pan_position(mouse.position_px - mouse.delta_px, world_from_projection, <<camera);
        increment := -(curr_pan_point - prev_pan_point);

        camera.eye_position += increment;
        camera.look_position += increment;
    }

    // Orbit about the look position using left button. Mouse delta is zero when current or previous mouse positions were invalid
    if mouse.left_down && (mouse.delta_px.x != 0 || mouse.delta_px.y != 0) {

        // Note: mouse_prev = mouse_pos - mouse_delta
        prev_arcball_vector := arcball_vector(to_ndc(mouse.position_px - mouse.delta_px));
        curr_arcball_vector := arcball_vector(to_ndc(mouse.position_px));

        arcball_axis4_ndc := make_vector4(cross_product(prev_arcball_vector, curr_arcball_vector), 1);
        arcball_axis_world := (world_from_projection * arcball_axis4_ndc).xyz;
        arcball_angle := angle(prev_arcball_vector, curr_arcball_vector);

        // @Cleanup fishy negative sign and rotation speed multiplier should be chosen so screen top/bottom or left/right rotates the scene by tau or tau/2 respectively.
        q : Quaternion = ---;
        rotation_speed :: -5.;
        set_from_axis_and_angle(*q, arcball_axis_world,  rotation_speed * arcball_angle);

        // @TODO user settable to world origin or object origin etc
        arcball_pivot := camera.look_position;
        // arcball_pivot := .{0, 0, 0};
        camera.eye_position = arcball_pivot + rotate(camera.eye_position - arcball_pivot, q);
        camera.up_direction = rotate(camera.up_direction, q);
    }

    // Zoom with right down or scrolling
    increment : float = 0;
    if mouse.right_down {
        increment = xx -0.03 * mouse.delta_px.y;
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
    up_direction = .{0, 1, 0};

    view_from_world := make_look_at_matrix(camera);
    view_min := view_from_world * make_vector4(world_box.min_point.x, world_box.min_point.y, 0, 1);
    view_max := view_from_world * make_vector4(world_box.max_point.x, world_box.max_point.y, 0, 1);

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
    camera.right = max(camera.right, aspect_ratio_horizontal_over_vertical * 0.1);
    camera.left = min(camera.left, -aspect_ratio_horizontal_over_vertical * 0.1);;
}

// @Cleanup use Math.make_look_at_matrix here
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

#scope_file

//
// Get a normalized vector from the center of the virtual ball O to a
// point P on the virtual ball surface, such that P is aligned on
// screen's (X,Y) coordinates.  If (X,Y) is too far away from the
// sphere, return the nearest point on the virtual ball surface.
//
// See  https://en.wikibooks.org/wiki/OpenGL_Programming/Modern_OpenGL_Tutorial_Arcball
arcball_vector :: (pos_ndc : Vector2) -> Vector3 {
    using result := make_vector3(pos_ndc.x, pos_ndc.y, 0);
    d2 := x*x + y*y;
    if d2 <= 1. {
        z = sqrt(1. - d2);
    } else {
        result = normalize(result);
    }
    return result;
}

// Return normalised device coordinates corresponding to the pixel position.
to_ndc :: (position_px : Vector2) -> Vector2
{
    position_ndc : Vector2 = ---;
    position_ndc.x = 2 * position_px.x / cast(float)current_window_width - 1;
    position_ndc.y = 2 * position_px.y / cast(float)current_window_height - 1;
    position_ndc.y *= -1; // (-1,-1) => bottom-left of screen, (+1,+1) => top-right of screen
    return position_ndc;
}


geom :: #import "geometry";
#load "numeric.jai";
#load "geometric_operations.jai";