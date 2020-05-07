Eek :: enum { A; B; C; }

Bar :: struct {
    i : int;
}

Foo :: struct {
    i : int;
    u : u8;
    f : float32;
    d : float64;
    e : Eek;
    b : Bar;
    z : Zot;

    Zot :: struct {
        i : int;
    }
}
