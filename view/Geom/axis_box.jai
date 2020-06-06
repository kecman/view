#scope_file

#import "Math";
#import "Basic";
#import "Compiler";

#scope_export

AxisBox :: struct (N : int)
 {
    #if N == 2 {
        Point :: Vector2;
    } else #if N == 3 {
        Point :: Vector3;
    } else {
        #run compiler_report_error(#file, #line, 0, "AxisBox must be 2D or 3D"); // @TODO better way which reports the call site?
    }

    min : Point;
    max : Point;
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

make_axis_box :: (min : Vector2, max : Vector2) -> AxisBox(2) {
    assert(is_finite(min.x) && is_finite(min.y));
    assert(is_finite(max.x) && is_finite(max.y));

    box : AxisBox(2);
    box.min = min;
    box.max = max;

    return box;
}

expand :: (box : *$T/AxisBox, point : T.Point) {
    for * box.min.component {
        << it = min(<< it, point.component[it_index]);
    }
    for * box.max.component {
        << it = max(<< it, point.component[it_index]);
    }
}

#scope_file



// polyline_bounds