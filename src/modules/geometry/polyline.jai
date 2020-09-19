Polyline2 :: Polyline(Vector2);
Polyline_Soup2 :: Polyline_Soup(Vector2);

Polyline3 :: Polyline(Vector3);
Polyline_Soup3 :: Polyline_Soup(Vector3);

Polyline :: struct (Point : Type) #modify check_vector(Point) {
    points : [..]Point;
}

polyline_free_and_reset :: (shape : *$T/Polyline) {
    array_reset(*shape.points);
}

Polyline_Soup :: struct (Point : Type) #modify check_vector(Point) {
    polylines : [..]Polyline(Point);
}

polyline_soup_free_and_reset :: (shape : *$T/Polyline_Soup) {
    for * shape.polylines polyline_free_and_reset(it);
    array_reset(*shape.polylines);
}

print_Polyline_Soup2 :: (shape : Polyline_Soup2) {
    print("%\n", shape);
    for l, li : shape.polylines {
        print("- line[%] %\n", li, l);
        for p, pi : l.points {
            print("-- point[%] %\n", pi, p);
        }
    }
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
