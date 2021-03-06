FLOAT_MACHINE_EPSILON :: 0.0001; // @FIXME

almost_equal :: (a : float, b : float, epsilon : float = 10 * FLOAT_MACHINE_EPSILON, scale : float = 1.0) -> bool
{
    // exact comparison allows to handle infinities and prevents from getting FPE triggered by (inf - inf)
    exactly_equal := (a == b);
    return exactly_equal || (abs(a - b) < epsilon * (scale + abs(a) + abs(b)));
}

angle :: (a : Vector3, b : Vector3, normalize : bool = false) -> float
{
    if normalize {
        // @Cleanup make this #if and use a = normalize(a), currently this looks like a @CompilerBug
        normalize_or_z_axis(*a);
        normalize_or_z_axis(*b);
        // a = normalize(a);
        // b = normalize(b);
    }
    // Following https://people.eecs.berkeley.edu/~wkahan/MathH110/Cross.pdf
    return 2 * atan2(length(a - b), length(a + b));
}

angle_unit :: #bake_arguments angle(normalize = false);


cwise_max :: (v : Vector3) -> float, int
{
    max_component := v.component[0];
    max_index     := 0;
    for d : 0..2 {
        if v.component[d] > max_component {
            max_component = v.component[d];
            max_index     = d;
        }
    }
    return max_component, max_index;
}

cwise_min :: (v : Vector3) -> float, int
{
    min_component := v.component[0];
    min_index     := 0;
    for d : 0..2 {
        if v.component[d] < min_component {
            min_component = v.component[d];
            min_index     = d;
        }
    }
    return min_component, min_index;
}

// @CompilerBug remove this when != is added to the Jai Math module
operator!= :: (a: Vector3, b: Vector3) -> bool {
    return a.x != b.x || a.y != b.y || a.z != b.z;
}

transform_point :: (point : Vector3, transform : Matrix4) -> Vector3
{
    return (transform * make_vector4(point, 1.)).xyz;
}

/*
Bivector3 :: struct {
    x, y, z : float;

#place x;
    _23 : float = ---;
#place y;
    _31 : float = ---;
#place z;
    _11 : float = ---;
}

Rotor3 :: struct {
    x, y, z, w : float;

#place x;
    xyz : Bivector3 = ---;
};
*/