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

expand :: (using box : *$T/AxisBox, point : T.Point) {
    for d : 0..T.dim-1 {
        min_point.component[d] = min(min_point.component[d], point.component[d]);
        max_point.component[d] = max(max_point.component[d], point.component[d]);
    }
}

center_point :: (using box : *$T/AxisBox) -> T.Point #must {
    return (max_point + min_point) / 2;
}

offset :: (box : *$T/AxisBox, increment : float) {
    for d : 0..T.dim-1 {
        box.min_point.component[d] -= increment;
        box.max_point.component[d] += increment;
    }
}

offset :: (using box : *$T/AxisBox, increment : T.Vector) {
    for d : 0..T.dim-1 {
        box.min_point.component[d] -= increment.component[d];
        box.max_point.component[d] += increment.component[d];
    }
}

extents :: (using box : *$T/AxisBox) -> T.Vector #must {
    result := max_point - min_point;
    return result;
}

#scope_file



// polyline_bounds