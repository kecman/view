#scope_file

#import "Math";

#scope_export

#load "axis_box.jai";
#load "polyline.jai";

make_look_at_matrix :: (eye : Vector3, center : Vector3, up : Vector3) -> Matrix4 #must {

    f := normalize_or_z_axis(center - eye);
    s := normalize_or_z_axis(cross(f, up));
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
    m.coef[0][3] = -dot(s, eye);
    m.coef[1][3] = -dot(u, eye);
    m.coef[2][3] =  dot(f, eye);

    return m;
}

to_radians :: (degrees : float) -> float {
    scale :: PI / 180;
    return degrees * scale;
}