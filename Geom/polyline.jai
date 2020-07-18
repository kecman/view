#scope_file

#import "Math";
#import "Compiler";

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
    #if dim == 2 {
        Point :: Vector2;
    } else #if dim == 3 {
        Point :: Vector3;
    } else {
        #run compiler_report_error(#file, #line, 0, "Polyline must be 2D or 3D"); // @TODO better way which reports the call site?
    }

    polylines : [..]Polyline(dim);
}

Polyline_Soup2 :: Polyline_Soup(2);
Polyline_Soup3 :: Polyline_Soup(3);

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
