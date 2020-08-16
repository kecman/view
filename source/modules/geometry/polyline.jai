Polyline2 :: Polyline(Vector2);
Polyline_Soup2 :: Polyline_Soup(Vector2);
Ring2 :: Ring(Vector2);
Polygon2 :: Polygon(Vector2);
Polygon_Soup2 :: Polygon_Soup(Vector2);

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

// A ring (aka linear ring) is a closed line (last point == first point) which should not be self-intersecting
Ring :: struct (Point : Type) #modify check_vector(Point) {
    points : [..]Point; // last point == first point
}

ring_free_and_reset :: (shape : *$T/Ring) {
    array_reset(*shape.points);
}

Polygon :: struct (Point : Type) #modify check_vector(Point) {
    outer_ring : Ring(Point);
    inner_rings : [..]Ring(Point);
}

polygon_free_and_reset :: (shape : *$T/Polygon) {
    ring_free_and_reset(*shape.outer_ring);
    for * shape.inner_rings ring_free_and_reset(it);
    array_reset(*shape.inner_rings);
}

Polygon_Soup :: struct (Point : Type) #modify check_vector(Point) {
    polygons : [..]Polygon(Point);
}

polygon_soup_free_and_reset :: (shape : *$T/Polygon_Soup) {
    for * shape.polygons polygon_free_and_reset(it);
    array_reset(*shape.polygons);
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
