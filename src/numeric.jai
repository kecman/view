#import "Math";

angle :: (a : Vector3, b : Vector3, $normalize : bool = false) -> float {
    #if normalize {
        a = normalize(a);
        b = normalize(b);
    }
    // Following https://people.eecs.berkeley.edu/~wkahan/MathH110/Cross.pdf
    return 2 * atan2(length(a - b), length(a + b));
}

/*
Bivector3 :: struct {
    x, y, z : float;

#place x;
    _23 : float = ---;
#place y;
    _31 : float = ---;
#place z;
    _11 : float = ---;
}

Rotor3 :: struct {
    x, y, z, w : float;

#place x;
    xyz : Bivector3 = ---;
};
*/