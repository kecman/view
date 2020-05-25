#scope_file

Math :: #import "Math";

#scope_export

make_look_at_matrix :: (eye : Math.Vector3, center : Math.Vector3, up : Math.Vector3) -> Math.Matrix4 #must {

    f := Math.normalize_or_z_axis(Math.operator-(center, eye));
    // f := Math.normalize_or_z_axis(center - eye);
    s := Math.normalize_or_z_axis(Math.cross(f, up));
    u := Math.cross(s, f);

    m := Math.matrix4_identity();

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
    m.coef[0][3] = -Math.dot(s, eye);
    m.coef[1][3] = -Math.dot(u, eye);
    m.coef[2][3] =  Math.dot(f, eye);

    return m;
}