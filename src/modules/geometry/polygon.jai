Ring2 :: Ring(Vector2);
Polygon2 :: Polygon(Vector2);
Polygon_Soup2 :: Polygon_Soup(Vector2);

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