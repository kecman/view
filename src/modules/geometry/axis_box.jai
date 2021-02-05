AxisBox2 :: AxisBox(Vector2);
AxisBox3 :: AxisBox(Vector3);

AxisBox :: struct(Point : Type) {
    Vector :: Point;
    min_point : Point;
    max_point : Point;
};

// Initialise `box` to a state where `is_empty` returns true and where we can start calling `expand`
init :: (using box : *$T/AxisBox) {
    FLOAT32_NEGATIVE_INFINITY :: 0hFF800000; // @Cleanup: -FLOAT32_INFINITY?

    dim :: #run vector_dimension(T.Point);
    for d : 0..dim-1 {
        min_point.component[d] = FLOAT32_INFINITY;
        max_point.component[d] = FLOAT32_NEGATIVE_INFINITY;
    }
}

make_axis_box :: (min_point : Vector2, max_point : Vector2) -> AxisBox2 #must {
    assert(is_finite(min_point.x) && is_finite(min_point.y));
    assert(is_finite(max_point.x) && is_finite(max_point.y));

    box : AxisBox2;
    box.min_point = min_point;
    box.max_point = max_point;

    return box;
}

to_polyline :: (using box : *AxisBox2) -> Polyline2 #must {
    polyline : Polyline2;
    array_add(*polyline.points, make_vector2(min_point.x, min_point.y));
    array_add(*polyline.points, make_vector2(max_point.x, min_point.y));
    array_add(*polyline.points, make_vector2(max_point.x, max_point.y));
    array_add(*polyline.points, make_vector2(min_point.x, max_point.y));
    array_add(*polyline.points, make_vector2(min_point.x, min_point.y));
    return polyline;
}

is_empty :: (using box : $T/AxisBox) -> bool #must {
    dim :: #run vector_dimension(T.Point);
    for d : 0..dim-1 {
        if min_point.component[d] > max_point.component[d] {
            return true;
        }
    }
    return false;
}

expand :: (using box : *$T/AxisBox, point : T.Point) {
    dim :: #run vector_dimension(T.Point);
    for d : 0..dim-1 {
        min_point.component[d] = min(min_point.component[d], point.component[d]);
        max_point.component[d] = max(max_point.component[d], point.component[d]);
    }
}

expand :: (using box : *$T/AxisBox, other : T) {
    if !is_empty(other) {
        expand(box, other.min_point);
        expand(box, other.max_point);
    }
}

center_point :: (using box : *$T/AxisBox) -> T.Point #must {
    return (max_point + min_point) / 2;
}

offset :: (using box : *$T/AxisBox, increment : float) {
    dim :: #run vector_dimension(T.Point);

    vector_increment : T.Vector;
    for d : 0..dim-1 {
        vector_increment.component[d] = increment;
    }
    offset(box, vector_increment);
}

offset :: (using box : *$T/AxisBox, increment : T.Vector) {
    dim :: #run vector_dimension(T.Point);

    if !is_empty(<<box) {
        for d : 0..dim-1 {
            assert(is_finite(increment.component[d]));
            min_point.component[d] -= increment.component[d];
            max_point.component[d] += increment.component[d];
        }
    }

    if is_empty(<<box) {
        init(box); // If box min/max invert after offset, use the standard representation of an empty box
    }
}

extents :: (using box : $T/AxisBox) -> T.Vector #must {
    dim :: #run vector_dimension(T.Point);

    box_extents : T.Vector;
    for d : 0..dim-1 {
        if min_point.component[d] <= max_point.component[d] {
            box_extents.component[d] = max_point.component[d] - min_point.component[d];
        }
    }
    return box_extents;
}

#scope_file

#import "Math";
#import "Basic";
#import "Compiler";
