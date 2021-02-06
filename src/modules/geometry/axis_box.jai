AxisBox2 :: AxisBox(Vector2);
AxisBox3 :: AxisBox(Vector3);

AxisBox :: struct(Point : Type) {
    Vector :: Point;

    DIM :: #run dimension_of(Point);
    Corner :: #run corner_type(DIM);

    min_point : Point;
    max_point : Point;

    // Initialize min and max to a state where `is_empty` returns true and where we can start calling `expand`
    #insert #run generate_initializer(DIM);
};

Corner2 :: enum u8 {
    XY_00 :: 0;
    XY_01 :: 1;
    XY_10 :: 2;
    XY_11 :: 3;
}

Corner3 :: enum u8 {
    XYZ_000 :: 0;
    XYZ_001 :: 1;
    XYZ_010 :: 2;
    XYZ_011 :: 3;
    XYZ_100 :: 4;
    XYZ_101 :: 5;
    XYZ_110 :: 6;
    XYZ_111 :: 7;
}

corner :: inline (using box : $T/AxisBox, corner : T.Corner) -> T.Point
{
    result : T.Point = ---;

    m := 1;
    for d : 0..2 {
        if m & cast(s64)corner {
            result.component[d] = box.max_point.component[d];
        } else {
            result.component[d] = box.min_point.component[d];
        }
        m *= 2;
    }

    return result;
}

// Iterates of the corners of the `box`
corners_iterator :: (using box : *$T/AxisBox, body : Code, flags : For_Flags) #expand
{
    #assert(flags == 0); // No options are supported

    `it_index := 0;
    for 0..(1 << T.DIM)-1 {
        `it := corner(<<box, xx it_index);
        #insert (remove=#assert(false)) body;
        it_index += 1;
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
    for d : 0..box.DIM-1 {
        if min_point.component[d] > max_point.component[d] {
            return true;
        }
    }
    return false;
}

expand :: (using box : *$T/AxisBox, point : T.Point) {
    for d : 0..box.DIM-1 {
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

center_point :: (using box : $T/AxisBox) -> T.Point #must {
    return (max_point + min_point) / 2;
}

offset :: (using box : *$T/AxisBox, increment : float) {
    vector_increment : T.Vector;
    for d : 0..box.DIM-1 {
        vector_increment.component[d] = increment;
    }
    offset(box, vector_increment);
}

offset :: (using box : *$T/AxisBox, increment : T.Vector) {
    if !is_empty(<<box) {
        for d : 0..box.DIM-1 {
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
    box_extents : T.Vector;
    for d : 0..box.DIM-1 {
        if min_point.component[d] <= max_point.component[d] {
            box_extents.component[d] = max_point.component[d] - min_point.component[d];
        }
    }
    return box_extents;
}

#scope_file

generate_initializer :: ($dim : s8) -> string {
    builder : String_Builder;
    defer free_buffers(*builder);
    for 0..dim-1 {
        print_to_builder(*builder, "min_point.component[%] =  FLOAT32_INFINITY;\n", it);
        print_to_builder(*builder, "max_point.component[%] = -FLOAT32_INFINITY;\n", it);
    }
    return builder_to_string(*builder);
}

corner_type :: ($dim : s8) -> Type {
    return ifx dim == 2 then Corner2 else Corner3;
}

#import "Math";
#import "Basic";
#import "Compiler";
