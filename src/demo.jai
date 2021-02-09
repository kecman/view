//
//  y
//  ^
//  7 +------------<------------+
//    |                         |
//    | 5 +-->---+   +-->---+   |
//    |   |      |   |      |   |
//    |   |      |   |      |   |
//    | 2 +--<---+   +--<---+   |
//    |   2      5   7     10   |
//  0 +------------>------------+
//    0                         12 --> x
//
make_polygon_a :: () -> Polygon2 {
    polygon : Polygon2;

    array_add(*polygon.outer_ring.points, .{0, 0}, .{12, 0}, .{12, 7}, .{0, 7}, .{0, 0});

    inner_ring_0 := array_add(*polygon.inner_rings);
    array_add(*inner_ring_0.points, .{2, 2}, .{2, 5}, .{5, 5}, .{5, 2}, .{2, 2}); 

    inner_ring_1 := array_add(*polygon.inner_rings);
    array_add(*inner_ring_1.points, .{7, 2}, .{7, 5}, .{10, 5}, .{10, 2}, .{7, 2}); 

    return polygon;
}


main :: ()
{
    polygon_a := make_polygon_a();
    print("polygon_a = %\n", polygon_a);

    box : AxisBox2 = ---;
    // box = make_axis_box(polygon_a.outer_ring.points[0], polygon_a.outer_ring.points[1]);
    // printv(#code box);

    // box = make_axis_box(..polygon_a.outer_ring.points);
    // printv(#code box);

    box = bounding_box(polygon_a);
    printv(#code box);

    {
        using polygon_a.outer_ring;
        box = make_axis_box(..points);
        printv(#code box);
    }

    // polygon_a_bbox := bounding_box(polygon_a);
    // print(#code polygon_a_bbox);

    // print("box = %, type_of(box) = %\n", box, type_of(box));
    // print("%\n", inline fib(4));
}

#run main();






// fib :: inline (n : int) -> int {
//     if n < 2 return n;
//     f_nm2, f_nm1, f_n := 0, 1, 0;
//     for 2..n f_n = f_nm1 + f_nm2;
//     return f_n;
// }

#import "Basic";
#import "geometry";

#load "carpet.jai";






goofy :: () {

    // Polymorphic function with polymorphic return type
    foo :: () -> $T {
        a : T;
        print("T = %, size_of(T) = %\n", T, size_of(T));
        return a;
    }

    foo_int :: #bake_constants foo(T=int);
    // foo();
    foo_int();

}