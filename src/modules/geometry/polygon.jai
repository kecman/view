// @Cleanup: explicitly allocator and array views, see e.g., Hash_Table.jai

//
// Ring. A closed line (last point == first point) which should not be self-intersecting, inside is on the left of the points
//

Ring :: struct {
    Point :: Vector2;
    Edge :: Segment(Point);

    points : [..]Point; // last point == first point
}

deinit :: (shape : *Ring)
{
    array_reset(*shape.points);
}

area :: (using ring : Ring) -> float
{
    // See http://geomalgorithms.com/a01-_area.html#2D%20Polygons
    // A more efficient version needs to iterate over triples of vertices
    area := 0.;
    for :segment_iterator segment, index : ring {
        using segment;
        area += (from_point.x + to_point.x) * (to_point.y - from_point.y);
    }
    return area / 2.;
}

//
// Polygon. One outer Ring, and zero or more inner rings describing holes, inside is on the left of the points
//

Polygon :: struct {
    Point :: Ring.Point;
    Edge :: Ring.Edge;

    outer_ring : Ring;
    inner_rings : [..]Ring;
}

deinit :: (shape : *Polygon)
{
    deinit(*shape.outer_ring);
    for * shape.inner_rings deinit(it);
    array_reset(*shape.inner_rings);
}

bounding_box :: (using polygon : Polygon) -> AxisBox2
{
    return make_axis_box(..outer_ring.points);
}

area :: (using polygon : Polygon) -> float
{
    result := area(outer_ring);
    for inner_rings {
        result += area(it);
    }
    return result;
}

//
// Iterators.
//

point_iterator :: (using polygon : *Polygon, body : Code, flags : For_Flags, reverse : bool) #expand
{
    BY_POINTER :: cast(bool)(flags & .POINTER);
    #if flags & .POINTER {
    `it : *Point2 = ---;
    } else {
    `it : Point2 = ---;
    }
    `it_index := 0;

    // print("outer ring:\n");
    for *=BY_POINTER <=reverse point, point_index : outer_ring.points {
        it = point;
        #insert body;
        it_index += 1;
    }

    for <=reverse inner_ring, inner_ring_index : inner_rings {
        // print("inner ring %:\n", inner_ring_index);
        for *=BY_POINTER <=reverse point, point_index : inner_ring.points {
            it = point;
            #insert body;
            it_index += 1;
        }
    }
}

point_forward_iterator :: #bake_arguments point_iterator(reverse=false);
point_reverse_iterator :: #bake_arguments point_iterator(reverse=true);

segment_iterator :: (using ring : *Ring, body : Code, flags : For_Flags) #expand
{
    #assert(flags == 0); // No options are supported.

    // print_stack_trace(context.stack_trace);

    segment_count := points.count - 1;

    `it_index := 0;
    for 0..segment_count-1 {
        `it : Ring.Edge = ---;
        it.from_point = *points[it_index];
        it.to_point   = *points[it_index + 1];

        #insert (remove=#assert(false)) body;

        it_index += 1;
    }
}


//
// Polygon Soup.
//

Polygon_Soup :: struct
{
    Point :: Polygon.Point;
    Edge :: Polygon.Edge;

    polygons : [..]Polygon;
}

deinit :: (shape : *Polygon_Soup)
{
    for * shape.polygons deinit(it);
    array_reset(*shape.polygons);
}

print_Polygon_Soup :: (shape : Polygon_Soup, print_points : bool = false)
{
    print("print_Polygon_Soup:\n %\n", shape);
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