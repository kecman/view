#import "Basic";
#import "Math";

// Hmm, seems not to be a problem here...

Polyline2 :: struct {
    points : [..] Vector2;
    // more stuff ...
}

print_polyline :: (polyline : *Polyline2) {
    for polyline print("% %\n", it_index, it);
}

main :: () {
    polyline : Polyline2;
    array_add(*polyline.points, make_vector2(1, 1));
    array_add(*polyline.points, make_vector2(2, 2));
    array_add(*polyline.points, make_vector2(3, 3));
    print_polyline(*polyline);
    // for polyline.points print("% %\n", it_index, it);
}