Ring2 :: Ring(Vector2);
Polygon2 :: Polygon(Vector2);
Polygon_Soup2 :: Polygon_Soup(Vector2);

// A ring (aka linear ring) is a closed line (last point == first point) which should not be self-intersecting
Ring :: struct (Point : Type) #modify check_vector(Point) {
    points : [..]Point; // last point == first point
}

deinit_ring :: (shape : *$T/Ring) {
    array_reset(*shape.points);
}

Polygon :: struct (Point : Type) #modify check_vector(Point) {
    // @Cleanup: consider explicitly storing the allocator and storing slices, see e.g., Hash_Table.jai
    outer_ring : Ring(Point);
    inner_rings : [..]Ring(Point);
}

deinit_polygon :: (shape : *$T/Polygon) {
    deinit_ring(*shape.outer_ring);
    for * shape.inner_rings deinit_ring(it);
    array_reset(*shape.inner_rings);
}

Polygon_Soup :: struct (Point : Type) #modify check_vector(Point) {
    polygons : [..]Polygon(Point);
}

deinit_polygon_soup :: (shape : *$T/Polygon_Soup) {
    for * shape.polygons deinit_polygon(it);
    array_reset(*shape.polygons);
}

print_Polygon_Soup :: (shape : $T/Polygon_Soup, print_points : bool = false) {
    print("print_Polygon_Soup2:\n %\n", shape);
    for shape.polygons {
        print("  outer_ring\n %\n", it.outer_ring);
        for it.inner_rings {
            print("  inner_ring[%]\n %\n", it_index, it);
        }
        if print_points {
            print("  outer_ring points: ");
            for it.outer_ring.points {
                print("[%] %,", it_index, it);
            }
            for it.inner_rings {
                print("\n  inner_ring[%] points: ", it_index);
                for it.points {
                    print("[%] %,", it_index, it);
                }
            }
        }
    }
}