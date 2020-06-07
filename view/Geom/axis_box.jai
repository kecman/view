#scope_file

#import "Math";
#import "Basic";
#import "Compiler";

#scope_export

AxisBox :: struct (dim : int)
 {
    #if dim == 2 {
        Point :: Vector2;
        Vector :: Vector2;
    } else #if dim == 3 {
        Point :: Vector3;
        Vector :: Vector3;
    } else {
        #run compiler_report_error(#file, #line, 0, "AxisBox must be 2D or 3D"); // @TODO better way which reports the call site?
    }

    min_point : Point;
    max_point : Point;
};

AxisBox2 :: AxisBox(2);
AxisBox3 :: AxisBox(3);

// @Question: [$N]float does not work, similar thing happens in the String module
// make_axisbox :: (min : [$N]float, max : [N]float) -> AxisBox(N) {
//     box : AxisBox(N);
//     box.min = min;
//     box.max = max;
//     return box;
// }

// Initialise `box` to a state where `is_empty` returns true and where we can start calling `expand`
init :: (using box : *$T/AxisBox) {
    for d : 0..T.dim-1 {
        #if type_of(T.Point.x) == float32 {
            min_point.component[d] = FLOAT32_INFINITY;
            max_point.component[d] = FLOAT32_NEGATIVE_INFINITY;
        } else {
            // @Incomplete: We can't actually make a box with component type float64
            min_point.component[d] = FLOAT64_INFINITY;
            max_point.component[d] = FLOAT64_NEGATIVE_INFINITY;
        }
    }
}

make_axis_box :: (min_point : Vector2, max_point : Vector2) -> AxisBox(2) #must {
    assert(is_finite(min_point.x) && is_finite(min_point.y));
    assert(is_finite(max_point.x) && is_finite(max_point.y));

    box : AxisBox(2);
    box.min_point = min_point;
    box.max_point = max_point;

    return box;
}

is_empty :: (using box : *$T/AxisBox) -> bool #must {
    for d : 0..T.dim-1 {
        if min_point.component[d] > max_point.component[d] {
            return true;
        }
    }
    return false;
}

expand :: (using box : *$T/AxisBox, point : T.Point) {
    for d : 0..T.dim-1 {
        min_point.component[d] = min(min_point.component[d], point.component[d]);
        max_point.component[d] = max(max_point.component[d], point.component[d]);
    }
}

center_point :: (using box : *$T/AxisBox) -> T.Point #must {
    return (max_point + min_point) / 2;
}

offset :: (using box : *$T/AxisBox, increment : float) {
    vector_increment : T.Vector;
    for d : 0..T.dim-1 {
        vector_increment.component[d] = increment;
    }
    offset(box, vector_increment);
}

offset :: (using box : *$T/AxisBox, increment : T.Vector) {
    if !is_empty(box) {
        for d : 0..T.dim-1 {
            assert(is_finite(increment.component[d]));
            min_point.component[d] -= increment.component[d];
            max_point.component[d] += increment.component[d];
        }
    }

    if is_empty(box) {
        init(box); // If box min/max invert after offset, use the standard representation of an empty box
    }
}

extents :: (using box : *$T/AxisBox) -> T.Vector #must {
    box_extents : T.Vector;
    for d : 0..T.dim-1 {
        if min_point.component[d] <= max_point.component[d] {
            box_extents.component[d] = max_point.component[d] - min_point.component[d];
        }
    }
    return box_extents;
}