#scope_file

#import "Math";
#import "Compiler";
#import "GL"; // @TODO remove gl stuff from this file?

#scope_export

Polyline :: struct (dim : int) {
    #if dim == 2 {
        Point :: Vector2;
    } else #if dim == 3 {
        Point :: Vector3;
    } else {
        #run compiler_report_error(#file, #line, 0, "Polyline must be 2D or 3D"); // @TODO better way which reports the call site?
    }

    points : [..] Point;

    buffer_id : GLuint;
    is_dirty := true;
}

Polyline2 :: Polyline(2);

bounding_box :: (polyline : *$T/Polyline) -> AxisBox(T.dim) #must {
    box : AxisBox(T.dim); // @Cleanup: Can we do this with named return values?
    init(*box);
    for polyline.points expand(*box, it);
    return box;
}

polyline_make_box :: () -> Polyline2 #must {
    polyline : Polyline2;
    array_add(*polyline.points, make_vector2(-150, -50));
    array_add(*polyline.points, make_vector2(-150,  50));
    array_add(*polyline.points, make_vector2( 150,  50));
    array_add(*polyline.points, make_vector2( 150, -50));
    array_add(*polyline.points, make_vector2(-150, -50));
    buffer_polyline(*polyline);
    return polyline;
}

buffer_polyline :: (using polyline : *$T/Polyline) {
    if is_dirty {
        if !buffer_id {
            glGenBuffers(1, *buffer_id);
        }
        glBindBuffer(GL_ARRAY_BUFFER, buffer_id);
        glBufferData(GL_ARRAY_BUFFER, size_of(type_of(points[0])) * points.count, points.data, GL_STATIC_DRAW);
        is_dirty = false;
    }
}