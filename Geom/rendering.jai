Renderable_Geometry_Type :: enum {
    POLYLINE2       :: 0;
    POLYLINE_SOUP2  :: 1;
    // POLYLINE3;
    // POLYLINE_SOUP3;
    // OBJ;
}

Renderable_Geometry :: struct {
    type : Renderable_Geometry_Type;

    vbo : GLuint;
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

buffer_polyline :: (using polyline : *$T/Renderable_Polyline2) {
    if is_dirty {
        if !vbo {
            glGenBuffers(1, *vbo);
        }
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, size_of(type_of(points[0])) * points.count, points.data, GL_STATIC_DRAW);
        is_dirty = false;
    }
}

buffer_polyline_soup :: (using soup : *$T/Renderable_Polyline_Soup2) {
    if is_dirty {
        if !vbo {
            glGenBuffers(1, *vbo);
        }
        glBindBuffer(GL_ARRAY_BUFFER, vbo);

        // @FIXME
        // @FIXME
        // @FIXME How to send points and indices separately?
        // @FIXME
        // @FIXME

        glBufferData(GL_ARRAY_BUFFER, size_of(type_of(points[0])) * points.count, points.data, GL_STATIC_DRAW);

    // glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gl_ib_handle);
    // glBufferData(GL_ELEMENT_ARRAY_BUFFER, index_array.count * size_of(u16), index_array.data, GL_STREAM_DRAW);
        
        is_dirty = false;
    }
}