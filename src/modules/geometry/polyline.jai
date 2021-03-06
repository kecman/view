//
// Polyline.
//

Polyline :: struct ($Point : Type)
{
    #run ensure_2d_or_3d(Point);
    points : [..]Point;
}

Polyline2 :: Polyline(Vector2);
Polyline3 :: Polyline(Vector3);

deinit :: (shape : *$T/Polyline) {
    array_reset(*shape.points);
}

is_empty :: (polyline : $T/Polyline) -> bool #must {
    return polyline.points.count < 2;
}

bounding_box :: (using polyline : $T/Polyline) -> AxisBox(T.Point) #must {
    box : AxisBox(T.Point);
    for points {
        expand(*box, it);
    }
    return box;
}

//
// Polyline Soup.
//

Polyline_Soup :: struct ($Point : Type)
{
    #run ensure_2d_or_3d(Point);
    polylines : [..]Polyline(Point);
}

Polyline_Soup2 :: Polyline_Soup(Vector2);
Polyline_Soup3 :: Polyline_Soup(Vector3);

deinit :: (shape : *$T/Polyline_Soup) {
    for * shape.polylines deinit(it);
    array_reset(*shape.polylines);
}

is_empty :: (polyline_soup : $T/Polyline_Soup) -> bool #must {
    for polyline_soup.polylines {
        if !is_empty(it) {
            return false;
        }
    }
    return true;
}

bounding_box :: (using polyline_soup : $T/Polyline_Soup) -> AxisBox(T.Point) #must {
    box : AxisBox(T.Point);
    for * polylines {
        polyline_box := bounding_box(it);
        expand(*box, polyline_box);
    }
    return box;
}

point_count :: (using polyline_soup : $T/Polyline_Soup) -> int
{
    count : int;
    for polyline : polyline_soup.polylines {
        count += polyline.points.count;
    }
    return count;
}

print_Polyline_Soup :: (shape : $T/Polyline_Soup, print_points := false) {
    print("print_Polyline_Soup: \n%\n", shape);
    for l, li : shape.polylines {
        print("- line[%] %\n", li, l);
        if print_points {
            for p, pi : l.points {
                print("-- point[%] %\n", pi, p);
            }
        }
    }
}

#scope_file

#import "Math";
#import "Compiler";
