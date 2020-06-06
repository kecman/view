#scope_file

#import "Math";
#import "GL";

#scope_export

Polyline2 :: struct {
    Point :: Vector2;
    points : [..] Point;

    buffer_id : GLuint;
    is_dirty := true;
}

polyline_make_box :: () -> Polyline2 #must {
    polyline : Polyline2;
    array_add(*polyline.points, make_vector2(-50, -50));
    array_add(*polyline.points, make_vector2(-50,  50));
    array_add(*polyline.points, make_vector2( 50,  50));
    array_add(*polyline.points, make_vector2( 50, -50));
    array_add(*polyline.points, make_vector2(-50, -50));
    buffer_polyline(*polyline);
    return polyline;
}

buffer_polyline :: (using polyline : *Polyline2) {
    if is_dirty {
        if !buffer_id {
            glGenBuffers(1, *buffer_id);
        }
        glBindBuffer(GL_ARRAY_BUFFER, buffer_id);
        glBufferData(GL_ARRAY_BUFFER, size_of(type_of(points[0])) * points.count, points.data, GL_STATIC_DRAW);
        is_dirty = false;
    }
}