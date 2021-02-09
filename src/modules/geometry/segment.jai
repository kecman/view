Segment :: struct (Point : Type) {
    from_point : *Point = ---;
    to_point   : *Point = ---;
}

Indexed_Segment :: struct (Point : Type) {
    using Segment(Point);

    from_index : int = ---;
    to_index   : int = ---;
}
