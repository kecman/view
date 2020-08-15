Polyline2 :: Polyline(Vector2);
Polyline3 :: Polyline(Vector3);
Polyline_Soup2 :: Polyline_Soup(Vector2);
Polyline_Soup3 :: Polyline_Soup(Vector3);

Polyline :: struct (Point : Type) #modify check_vector(Point) {
    points : [..]Point;
}

Polyline_Soup :: struct (Point : Type) #modify check_vector(Point) {
    polylines : [..]Polyline(Point);
}

bounding_box :: (using polyline : *$T/Polyline) -> AxisBox(T.Point) #must {
    box : AxisBox(T.Point);
    init(*box);
    for points {
        expand(*box, it);
    }
    return box;
}

bounding_box :: (using polyline_soup : *$T/Polyline_Soup) -> AxisBox(T.Point) #must {
    box : AxisBox(T.Point);
    init(*box);
    for * polylines {
        polyline_box := bounding_box(it);
        expand(*box, *polyline_box);
    }
    return box;
}

#scope_file

#import "Math";
#import "Compiler";
