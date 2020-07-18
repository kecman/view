Renderable_Geometry_Type :: enum {
    POLYLINE2       :: 0;
    POLYLINE_SOUP2  :: 1;
    // POLYLINE3;
    // POLYLINE_SOUP3;
    // OBJ;
}

Renderable_Geometry :: struct {
    type : Renderable_Geometry_Type;

    vbo : GLuint; // vertex buffer object
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
    type = .POLYLINE2;
    visible = true;
    if is_dirty {
        if !vbo glGenBuffers(1, *vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, size_of(Point) * points.count, points.data, GL_STATIC_DRAW);
        is_dirty = false;
    }
}

buffer_polyline_soup :: (using soup : *$T/Renderable_Polyline_Soup2) {
    type = .POLYLINE_SOUP2;
    visible = true;
    if is_dirty {
        if !vbo glGenBuffers(1, *vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);

        num_points := 0;
        for polyline : polylines num_points += polyline.points.count;

        glBufferData(GL_ARRAY_BUFFER, size_of(Point) * num_points, null, GL_STATIC_DRAW);

        offset := 0;
        for polyline : polylines {
            glNamedBufferSubData(vbo, xx offset, size_of(Point) * polyline.points.count, polyline.points.data);
            offset += size_of(Point) * polyline.points.count;
        }

        is_dirty = false;
    }
}

#scope_file

#import "GL";