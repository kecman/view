#scope_file

#import "Math";
#import "Compiler";
#import "GL"; // @TODO remove gl stuff from this file?

#scope_export


// @Cleanup rename dim to Dim since it's 'compile time constant'?
Polyline :: struct (dim : int) {
    #if dim == 2 {
        Point :: Vector2;
    } else #if dim == 3 {
        Point :: Vector3;
    } else {
        #run compiler_report_error(#file, #line, 0, "Polyline must be 2D or 3D"); // @TODO better way which reports the call site?
    }

    points : [..]Point;
}

Polyline2 :: Polyline(2);
Polyline3 :: Polyline(3);

Polyline_Soup :: struct (dim : int) {
    Point : Polyline(dim).Point;
    polylines : [..]Polyline(dim);
}

Polyline_Soup2 :: Polyline_Soup(2);
Polyline_Soup3 :: Polyline_Soup(3);

Renderable_Geometry_Type :: enum {
    POLYLINE2       :: 0;
    POLYLINE_SOUP2  :: 1;
    // POLYLINE3;
    // POLYLINE_SOUP3;
    // OBJ;
}

Renderable_Geometry :: struct {
    type : Renderable_Geometry_Type;

    buffer_id : GLuint;
    is_dirty := true;
    filename : string; // @Cleanup rename to fully_pathed_filename
    visible : bool = true;
}

Renderable_Polyline2 :: struct {
    using renderable : Renderable_Geometry;
    line_color : Vector4;

    using geometry : Polyline(2);
}

Renderable_Polyline_Soup2 :: struct {
    using renderable : Renderable_Geometry;
    line_color : Vector4;

    using geometry : Polyline_Soup(2);
}

bounding_box :: (renderable_geometry : *Renderable_Geometry) -> AxisBox(2) #must {
    if #complete renderable_geometry.type == {
        case .POLYLINE2;
            polyline2 := cast(*Renderable_Polyline2)renderable_geometry;
            return bounding_box(polyline2);
        case .POLYLINE_SOUP2;
            return bounding_box((cast(*Renderable_Polyline_Soup2)renderable_geometry));
    }
}

bounding_box :: (polyline : *$T/Polyline) -> AxisBox(T.dim) #must {
    box : AxisBox(T.dim); // @Cleanup: Can we do this with named return values?
    init(*box);
    for polyline.points {
        expand(*box, it);
    }
    return box;
}

bounding_box :: (polyline_soup : *$T/Polyline_Soup) -> AxisBox(T.dim) #must {
    box : AxisBox(T.dim); // @Cleanup: Can we do this with named return values?
    init(*box);
    for * polyline_soup.polylines {
        polyline_box := bounding_box(it);
        expand(*box, *polyline_box);
    }
    return box;
}

buffer_polyline :: (using polyline : *$T/Renderable_Polyline2) {
    if is_dirty {
        if !buffer_id {
            glGenBuffers(1, *buffer_id);
        }
        glBindBuffer(GL_ARRAY_BUFFER, buffer_id);
        glBufferData(GL_ARRAY_BUFFER, size_of(type_of(points[0])) * points.count, points.data, GL_STATIC_DRAW);
        is_dirty = false;
    }
}

// @FIXME How to send points and indices separately?
buffer_polyline_soup :: (using soup : *$T/Renderable_Polyline_Soup2) {
    if is_dirty {
        if !buffer_id {
            glGenBuffers(1, *buffer_id);
        }
        glBindBuffer(GL_ARRAY_BUFFER, buffer_id);
        glBufferData(GL_ARRAY_BUFFER, size_of(type_of(points[0])) * points.count, points.data, GL_STATIC_DRAW);
        is_dirty = false;
    }
}