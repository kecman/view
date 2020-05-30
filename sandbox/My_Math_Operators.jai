#import "My_Math";

/*
operator - :: (a: Vector3, b: Vector3) -> Vector3 {
    r: Vector3 = ---;

    r.x = a.x - b.x;
    r.y = a.y - b.y;
    r.z = a.z - b.z;

    return r;
}
*/

operator + :: (a: Vector2, b: Vector2) -> Vector2 {
    r: Vector2 = ---;

    r.x = a.x + b.x;
    r.y = a.y + b.y;

    return r;
}

operator - :: (a: Vector2, b: Vector2) -> Vector2 {
    r: Vector2 = ---;

    r.x = a.x - b.x;
    r.y = a.y - b.y;

    return r;
}

operator * :: (a: Vector2, b: Vector2) -> Vector2 {
    r: Vector2 = ---;
    r.x = a.x * b.x;
    r.y = a.y * b.y;
    return r;
}    

operator * :: (a: Vector2, k: float) -> Vector2  #symmetric {
    r: Vector2 = ---;
    r.x = a.x * k;
    r.y = a.y * k;

    return r;
}    

operator / :: (a: Vector2, k: float) -> Vector2 {
    r: Vector2 = ---;
    denom := 1 / k;
    r.x = a.x * denom;
    r.y = a.y * denom;
    return r;
}

operator / :: (k: float, a: Vector2) -> Vector2 {
    r: Vector2 = ---;
    r.x = k / a.x;
    r.y = k / a.y;
    return r;
}    


operator== :: (a: Vector2, b: Vector2) -> bool {
    return a.x == b.x && a.y == b.y;
}

saturate :: (a: Vector2) -> Vector2 #must {
    r: Vector2 = ---;
    r.x = saturate(a.x);
    r.y = saturate(a.y);
    return r;
}



// Vector3 operators:

operator + :: (a: Vector3, b: Vector3) -> Vector3 {
    r: Vector3 = ---;

    r.x = a.x + b.x;
    r.y = a.y + b.y;
    r.z = a.z + b.z;

    return r;
}

operator - :: (a: Vector3, b: Vector3) -> Vector3 {
    r: Vector3 = ---;

    r.x = a.x - b.x;
    r.y = a.y - b.y;
    r.z = a.z - b.z;

    return r;
}

operator - :: (a: Vector3) -> Vector3 {
    r: Vector3 = ---;

    r.x = -a.x;
    r.y = -a.y;
    r.z = -a.z;

    return r;
}

operator * :: (a: Vector3, b: Vector3) -> Vector3 {
    r: Vector3 = ---;
    r.x = a.x * b.x;
    r.y = a.y * b.y;
    r.z = a.z * b.z;
    return r;
}    

// @Cleanup: Make some kind of syntax like:  k: float|float64  ??
// Or some other easy way to do polymorphism with a scalar constraint?
// operator * :: (a: Vector3, k: float) -> Vector3  #symmetric 
operator * :: (a: Vector3, k: float) -> Vector3  #symmetric {
    r: Vector3 = ---;
    r.x = a.x * k;
    r.y = a.y * k;
    r.z = a.z * k;

    return r;
}    

operator * :: (a: Vector3, k: float64) -> Vector3  #symmetric {
    r: Vector3 = ---;
    r.x = xx(a.x * k);
    r.y = xx(a.y * k);
    r.z = xx(a.z * k);

    return r;
}    

operator / :: (a: Vector3, k: float) -> Vector3 {
    r: Vector3 = ---;

    denom := 1 / k;
    r.x = a.x * denom;
    r.y = a.y * denom;
    r.z = a.z * denom;

    return r;
}

operator / :: (k: float, a: Vector3) -> Vector3 {
    r: Vector3 = ---;
    r.x = k / a.x;
    r.y = k / a.y;
    r.z = k / a.z;
    return r;
}    

operator== :: (a: Vector3, b: Vector3) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

saturate :: (a: Vector3) -> Vector3 #must {
    r: Vector3 = ---;
    r.x = saturate(a.x);
    r.y = saturate(a.y);
    r.z = saturate(a.z);
    return r;
}


// Vector4 operators:

operator + :: (a: Vector4, b: Vector4) -> Vector4 {
    r: Vector4 = ---;
    r.x = a.x + b.x;
    r.y = a.y + b.y;
    r.z = a.z + b.z;
    r.w = a.w + b.w;

    return r;
}

operator - :: (a: Vector4, b: Vector4) -> Vector4 {
    r: Vector4 = ---;
    r.x = a.x - b.x;
    r.y = a.y - b.y;
    r.z = a.z - b.z;
    r.w = a.w - b.w;

    return r;
}

operator * :: (a: Vector4, b: Vector4) -> Vector4 {
    r: Vector4 = ---;
    r.x = a.x * b.x;
    r.y = a.y * b.y;
    r.z = a.z * b.z;
    r.w = a.w * b.w;
    return r;
}    

operator * :: (a: Vector4, k: float) -> Vector4  #symmetric {
    r: Vector4 = ---;
    r.x = a.x * k;
    r.y = a.y * k;
    r.z = a.z * k;
    r.w = a.w * k;

    return r;
}    

operator / :: (a: Vector4, k: float) -> Vector4 {
    r: Vector4 = ---;

    denom := 1 / k;
    r.x = a.x * denom;
    r.y = a.y * denom;
    r.z = a.z * denom;
    r.w = a.w * denom;

    return r;
}

operator / :: (k: float, a: Vector4) -> Vector4 {
    r: Vector4 = ---;
    r.x = k / a.x;
    r.y = k / a.y;
    r.z = k / a.z;
    r.w = k / a.w;
    return r;
}    

operator== :: (a: Vector4, b: Vector4) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
}
operator!= :: (a: Vector4, b: Vector4) -> bool {    // @@ Isn't this generated automatically??
    return a.x != b.x || a.y != b.y || a.z != b.z || a.w != b.w;
}

saturate :: (a: Vector4) -> Vector4 #must {
    r: Vector4 = ---;
    r.x = saturate(a.x);
    r.y = saturate(a.y);
    r.z = saturate(a.z);
    r.w = saturate(a.w);
    return r;
}



// Quaternion operators:

operator + :: (a: Quaternion, b: Quaternion) -> Quaternion {
    r: Quaternion = ---;
    r.x = a.x + b.x;
    r.y = a.y + b.y;
    r.z = a.z + b.z;
    r.w = a.w + b.w;

    return r;
}

operator * :: (a: Quaternion, k: float) -> Quaternion  #symmetric {
    r: Quaternion = ---;
    r.x = a.x * k;
    r.y = a.y * k;
    r.z = a.z * k;
    r.w = a.w * k;

    return r;
}    

operator - :: (a: Quaternion, b: Quaternion) -> Quaternion {
    r: Quaternion = ---;
    r.x = a.x - b.x;
    r.y = a.y - b.y;
    r.z = a.z - b.z;
    r.w = a.w - b.w;

    return r;
}

operator * :: (m: Quaternion, a: Quaternion) -> Quaternion {
    v  := make_vector3(m.x,m.y,m.z);
    av := make_vector3(a.x,a.y,a.z);

    r: Quaternion;
    r.w = m.w * a.w - dot_product(v, av);

    rv := cross_product(v, av);

    av *= m.w;
    v  *= a.w;

    rv = rv + av + v;

    r.x = rv.x;
    r.y = rv.y;
    r.z = rv.z;

    return r;

}