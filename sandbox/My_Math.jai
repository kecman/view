#import "My_Math_Operators";

/*
Vector2 :: struct {
    x, y: float;

#place x;
    component: [2] float = ---;  // Compiler generates additional overwrite for unioned arrays. After review, this seems like not a bug, at least for version 1 of the language. Look in why.txt for the reason. This might be a bit error prone, but we can have Check.jai check for it.
}

Vector3 :: struct {
    x, y, z: float;

#place x;
    xy: Vector2 = ---;
#place y;
    yz: Vector2 = ---;

#place x;
    component: [3] float = ---;
}

make_vector3 :: (x: float, y: float, z: float) -> Vector3 {
    v: Vector3 = ---;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

do_op :: (v : Vector3, u : Vector3) -> Vector3 {
    return u - v;
}
*/

/*
   Owner: Jonathan Blow <jon@number-none.com>
   Description: Math routines.
 */

#scope_file
#import "Basic";
// IC: Math requires Basic for assert.
// We put our own swap in here to avoid that...
// assert, that's used in tests, so maybe when we figure out how to tell modules we just want parts of them, we only take the Basic dependency if you import the tests.  -jblow, 10 January 2019
#scope_export

// #load "cephes.jai";
// #load "plane.jai";
// #load "color.jai";
// #load "matrix.jai";


// Scalars constants

TAU : float : 6.283185;
TAU64 : float64 : 6.28318530717958648;

PI : float : 3.1415927;
PI64 : float64 : 3.141592653589793;

FLOAT16_MAX : float :   65504.0;

FLOAT32_MIN               :: 0h00800000;
FLOAT32_MAX               :: 0h7F7FFFFF;
FLOAT32_INFINITY          :: 0h7F800000;
FLOAT32_NEGATIVE_INFINITY :: 0hFF800000;

FLOAT32_NAN               :float: 0h7FBFFFFF; 

FLOAT64_MIN               :: 0h00100000_00000000;
FLOAT64_MAX               :: 0h7FEFFFFF_FFFFFFFF;
FLOAT64_INFINITY          :: 0h7FF00000_00000000;
FLOAT64_NEGATIVE_INFINITY :: 0hFFF00000_00000000;

S8_MIN  :s8:    -128;
S8_MAX  :s8:    127;
U8_MAX  :u8:    255;
S16_MIN :s16:   -32768;
S16_MAX :s16:   32767;
U16_MAX :u16:   0xffff;
S32_MIN :s32:   -2147483648;
S32_MAX :s32:   2147483647;
U32_MAX :u32:   0xffff_ffff;
S64_MIN :s64:   -9223372036854775808;
S64_MAX :s64:   9223372036854775807;
U64_MAX :u64:   0xffff_ffff_ffff_ffff;

INT_TO_FLOAT32_MAX :: 16777217;         // Largest integer such that it and all smaller integers can be stored in a 32bit float.

Clamp :: (pointer: *$T, low: T, high: T) {
    if <<pointer < low   { <<pointer = low; };
    if <<pointer > high  { <<pointer = high; };
} @NoProfile

// ## Scalar functions

// ### Integer functions

abs :: inline (x: int) -> int {
    if x < 0 return -x;
    return x;
}

abs :: inline (x: s32) -> s32 {
    if x < 0 return -x;
    return x;
}

log2 :: inline (x: int) -> int {
    // @@ Use BSR/CTZ/CLZ intrinsic for this?
    assert(x != 0);
    r := 0;
    x = x >> 1  ;
    while x {
        r += 1;
        x = x >> 1;
    }
    return r;
}


// ### Float functions

is_nan_is_inf :: (x: float64) -> (isnan: bool, isinf: bool) {
    uf := << cast(*u64)*x;

    unbiased_exponent := cast(s32) ((uf >> 52) & 0x7ff);  // @Feature: What we really mean here is "cast to whatever you think is a fast number, that is at least some size... [in this case it needs to be at least 11 bits!]
    
    if unbiased_exponent == 0x7ff {
        raw_mantissa := uf & 0xf_ffff_ffff_ffff;
        if raw_mantissa == 0 {
            return false, true;
        } else {
            return true, false;
        }
    }

    return false, false;
}

isnan :: (x: float64) -> bool {
    return is_nan_is_inf(x);
}

isinf :: (x: float64) -> bool {
    _, _isinf := is_nan_is_inf(x);
    return _isinf;
}

is_finite :: (x: float64) -> bool {
    nan, inf := is_nan_is_inf(x);
    return !nan && !inf;
}

is_nan_is_inf :: (x: float32) -> (isnan: bool, isinf: bool) {
    uf := << cast(*u32)*x;

    unbiased_exponent := (uf >> 23) & 0xff;
    if unbiased_exponent == 0xff {
        raw_mantissa := uf & 0x7f_ffff;
        if raw_mantissa == 0 {
            return false, true;
        } else {
            return true, false;
        }
    }

    return false, false;
}

isnan :: (x: float32) -> bool {
    return is_nan_is_inf(x);
}

isinf :: (x: float32) -> bool {
    _, _isinf := is_nan_is_inf(x);
    return _isinf;
}

is_finite :: (x: float) -> bool {
    nan, inf := is_nan_is_inf(x);
    return !nan && !inf;
}

#if OS_WINDOWS || OS_MACOSX {
    // Float64 versions.
    cos  :: (theta: float64) -> float64 #foreign crt;
    sin  :: (theta: float64) -> float64 #foreign crt;
    tan  :: (theta: float64) -> float64 #foreign crt;
    atan2 :: (y: float64, x: float64) -> float64 #foreign crt;
    atan :: (y: float64) -> float64 #foreign crt;
    acos :: (theta: float64) -> float64 #foreign crt;
    asin :: (theta: float64) -> float64 #foreign crt;
    sqrt :: (theta: float64) -> float64 #foreign crt;
    pow  :: (x: float64, power: float64) -> float64 #foreign crt;
    exp  :: (x: float64) -> float64 #foreign crt;
    abs :: (x: float64) -> float64 #foreign crt "fabs";
    fmod :: (x: float64, divisor: float64) -> float64 #foreign crt;
    log :: (x: float64) -> float64 #foreign crt;

    // Float32 versions.
    cos  :: (theta: float) -> float #foreign crt "cosf";
    sin  :: (theta: float) -> float #foreign crt "sinf";
    tan  :: (theta: float) -> float #foreign crt "tanf";
    atan2 :: (y: float, x: float) -> float #foreign crt "atan2f";
    atan :: (y: float) -> float #foreign crt "atanf";
    acos :: (theta: float) -> float #foreign crt "acosf";
    asin :: (theta: float) -> float #foreign crt "asinf";
    sqrt :: (theta: float) -> float #foreign crt "sqrtf";
    pow  :: (x: float, power: float) -> float #foreign crt "powf";
    exp  :: (x: float) -> float #foreign crt "expf";
    fmod :: (x: float, divisor: float) -> float #foreign crt "fmodf";   // x64 & arm only.

    //abs :: (x: float) -> float #foreign crt "fabsf";                    // arm only.
} else #if OS_LINUX {
    // Use external declarations for ease of controlling glibc versioned-symbols.

    // @Cleanup: Including files from another module is NOT OKAY.
    // Modules are individual units and you can't presume the existence of
    // files from another one.
    #load "/home/matija/Dropbox/jai/modules/POSIX/libm_bindings.jai";
}

// In the x86/x64 CRT these functions are inlines:
abs :: inline (x: float) -> float {
    return xx abs(cast(float64) x);
}


// This 'saturate' stuff is not necessarily a good name for a general-purpose routine.
// That's a graphics-specific name. These things should probably be in some kind of
// GPU Math library, or, I don't know.
saturate :: (f: float)   -> float   {  return clamp(f, 0, 1);  }
saturate :: (f: float64) -> float64 {  return clamp(f, 0, 1);  }
square   :: (a : $T) -> T {  return a * a;  }

// See: https://fgiesen.wordpress.com/2012/03/28/half-to-float-done-quic/
// This seems like a specialist routine that probably should be elsewhere.
half_to_float :: (h: u16) -> float {
    magic      :: 0h77800000;  // This is ((254 - 15) << 23) as a float.
    was_infnan :: 0h47800000;  // This is ((127 + 16) << 23) as a float.
    
    union { u: u32; f: float; };

    u = (cast(u32)h & 0x7fff) << 13;  // exponent/mantissa bits
    f *= magic;                       // exponent adjust
    if f >= was_infnan                // make sure Inf/NaN survive
        u |= 255 << 23;
    u |= (cast(u32)h & 0x8000) << 16; // sign bit
    return f;
}

// Vectors

Vector2 :: struct {
    x, y: float;

#place x;
    component: [2] float = ---;  // Compiler generates additional overwrite for unioned arrays. After review, this seems like not a bug, at least for version 1 of the language. Look in why.txt for the reason. This might be a bit error prone, but we can have Check.jai check for it.
}

Vector3 :: struct {
    x, y, z: float;

#place x;
    xy: Vector2 = ---;
#place y;
    yz: Vector2 = ---;

#place x;
    component: [3] float = ---;
}

Vector4 :: struct {
    x, y, z, w: float;

#place x;
    xy: Vector2 = ---;
#place y;
    yz: Vector2 = ---;
#place z;
    zw: Vector2 = ---;
#place x;
    xyz: Vector3 = ---;
#place y;
    yzw: Vector3 = ---;
#place x;
    component: [4] float = ---;
}

Quaternion :: struct {
    x, y, z:  float;
    w      := 1.0;
#place x;
    component: [4] float = ---;
}




dot :: dot_product;

dot_product :: (a: Vector2, b: Vector2) -> float {
    return a.x*b.x + a.y*b.y;
}

dot_product :: (a: Vector3, b: Vector3) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

dot_product :: (a: Quaternion, b: Quaternion) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
}


// @Incomplete: Would like to be able to do this:
// dot   :: dot_product;
// cross :: cross_product;

length :: (a: Vector2) -> float {
    return sqrt(a.x*a.x + a.y*a.y);
}

length :: (a: Vector3) -> float {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
}

length :: (a: Vector4) -> float {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z + a.w*a.w);
}

length :: (a: Quaternion) -> float {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z + a.w*a.w);
}

length_squared :: inline (a: Vector3) -> float {
    return a.x*a.x + a.y*a.y + a.z*a.z;
}

xy :: make_vector2;
make_vector2 :: (x: float) -> Vector2 {
    v: Vector2 = ---;
    v.x = x;
    v.y = x;
    return v;
}
make_vector2 :: (x: float, y: float) -> Vector2 {
    v: Vector2 = ---;
    v.x = x;
    v.y = y;
    return v;
}

xyz :: make_vector3;
rgb :: make_vector3;

make_vector3 :: (x: float) -> Vector3 {
    v: Vector3 = ---;
    v.x, v.y, v.z = x;
    return v;
}

make_vector3 :: (x: float, y: float, z: float) -> Vector3 {
    v: Vector3 = ---;
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}

make_vector3 :: (c: [3]float) -> Vector3 {
    v: Vector3 = ---;
    v.x = c[0];
    v.y = c[1];
    v.z = c[2];
    return v;
}

make_vector3 :: (v: Vector2, z: float) -> Vector3 {
    v3: Vector3 = ---;
    v3.x = v.x;
    v3.y = v.y;
    v3.z = z;
    return v3;
}


xyzw :: make_vector4;
rgba :: make_vector4;

make_vector4 :: (x: float) -> Vector4 {
    v: Vector4 = ---;
    v.x, v.y, v.z, v.w = x;
    return v;
}

make_vector4 :: (x: float, y: float, z: float, w: float) -> Vector4 {
    v: Vector4 = ---;
    v.x = x;
    v.y = y;
    v.z = z;
    v.w = w;
    return v;
}

make_vector4 :: (v: Vector2, z: float, w: float) -> Vector4 {
    v4: Vector4 = ---;
    v4.x = v.x;
    v4.y = v.y;
    v4.z = z;
    v4.w = w;
    return v4;
}

make_vector4 :: (v: Vector3, w: float) -> Vector4 {
    v4: Vector4 = ---;
    v4.x = v.x;
    v4.y = v.y;
    v4.z = v.z;
    v4.w = w;
    return v4;
}

make_quaternion :: (x: float, y: float, z: float, w: float) -> Quaternion {
    v: Quaternion = ---;
    v.x = x;
    v.y = y;
    v.z = z;
    v.w = w;
    return v;
}


quaternion_identity :: () -> Quaternion {
    return make_quaternion(0,0,0,1);
}


normalize_or_identity :: (using q: *Quaternion) -> float {
    sq := sqrt(x*x + y*y + z*z + w*w);
    if sq == 0 {
        w = 1;
        return sq;
    }

    factor := 1.0 / sq;
    x *= factor;
    y *= factor;
    z *= factor;
    w *= factor;
    
    return sq;
} @NoProfile


abs :: inline (v: Vector2) -> Vector2 {
    r: Vector2 = ---;
    r.x = abs(v.x);
    r.y = abs(v.y);
    return r;
}

abs :: inline (v: Vector3) -> Vector3 {
    r: Vector3 = ---;
    r.x = abs(v.x);
    r.y = abs(v.y);
    r.z = abs(v.z);
    return r;
}

abs :: inline (v: Vector4) -> Vector4 {
    r: Vector4 = ---;
    r.x = abs(v.x);
    r.y = abs(v.y);
    r.z = abs(v.z);
    r.w = abs(v.w);
    return r;
}

/*
Until we have operator overloading, don't define this because
we can't use it for vectors, etc.
lerp :: (a: $R, b: R, t: float) -> R {
    return a + (b - a) * t;
}
*/

lerp :: (a: float, b: float, t: float) -> float {
    return a + (b - a) * t;
} @NoProfile

lerp :: (a: Quaternion, b: Quaternion, t: float) -> Quaternion {
    r: Quaternion = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);
    r.z = a.z + t * (b.z - a.z);
    r.w = a.w + t * (b.w - a.w);

    return r;
} @NoProfile

lerp :: (a: Vector2, b: Vector2, t: float) -> Vector2 {
    r: Vector2 = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);

    return r;
} @NoProfile

lerp :: (a: Vector3, b: Vector3, t: float) -> Vector3 {
    r: Vector3 = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);
    r.z = a.z + t * (b.z - a.z);

    return r;
} @NoProfile

lerp :: (a: Vector4, b: Vector4, t: float) -> Vector4 {
    r: Vector4 = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);
    r.z = a.z + t * (b.z - a.z);
    r.w = a.w + t * (b.w - a.w);

    return r;
} @NoProfile

nlerp :: inline (p0: Quaternion, p1: Quaternion, fraction: float) -> Quaternion {
    result := lerp(p0, p1, fraction);
	normalize_or_identity(*result);

    return result;
}

slerp :: (start: Quaternion, end: Quaternion, t: float) -> Quaternion {
    // Input quaternions should be unit length or else
    // something broken will happen.

    // The technique below will work for input vectors of any
    // number of dimensions (you could write a templatized version
    // of the code, or one that takes a generic N-vector data type,
    // and it would just work).


    // Compute the cosine of the angle between the two vectors.
    dot := dot_product(start, end);

    DOT_THRESHOLD :: 0.9995;
    if dot > DOT_THRESHOLD {
        // If the inputs are too close for comfort, linearly interpolate
        // and normalize the result.
        result := lerp(start, end, t);
        normalize_or_identity(*result);
        return result;
    }

    Clamp(*dot, -1, 1);
    theta_0 := acos(dot);  // Angle between input vectors
    theta   := theta_0 * t;  // Angle between 'start' and result

    e1 := start;
    e2 := end - start * dot;
    normalize_or_identity(*e2);              // { e1, e2 } is now an orthonormal basis

    return (e1 * cos(theta)) + (e2 * sin(theta));
}

multiply :: (v: Vector2, f: float) -> Vector2 {
    return make_vector2(v.x * f, v.y * f);
}

multiply :: (v: Vector3, f: float) -> Vector3 {
    return make_vector3(v.x*f, v.y*f, v.z*f);
}

distance :: (a: Vector4, b: Vector4) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;
    dz := b.z - a.z;
    dw := b.w - a.w;

    return sqrt(dx*dx + dy*dy + dz*dz + dw*dw);
}

distance :: (a: Vector3, b: Vector3) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;
    dz := b.z - a.z;

    return sqrt(dx*dx + dy*dy + dz*dz);
}

distance_squared :: inline (a: Vector3, b: Vector3) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;
    dz := b.z - a.z;

    return dx*dx + dy*dy + dz*dz;
}

distance :: (a: Vector2, b: Vector2) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;

    return sqrt(dx*dx + dy*dy);
}

// Normalize that operates in place and returns length. @@ This is not very useful without struct initializer syntax.
normalize :: (using v: *Vector3, epsilon := 0, fallback:Vector3/*:=make_vector3(0, 0, 0)*/) -> float {
    sq := sqrt(x*x + y*y + z*z);
    if sq == 0 {
        <<v = fallback;
        return sq;
    }

    factor := 1.0 / sq;
    x *= factor;
    y *= factor;
    z *= factor;

    return sq;
} @NoProfile

normalize_or_z_axis :: inline (using v: *Vector3) -> float {
    return normalize(v, fallback=make_vector3(0,0,1));
} @NoProfile

normalize_or_zero :: inline (using v: *Vector3) -> float {
    return normalize(v, fallback=make_vector3(0,0,0));
} @NoProfile

// To be used like the glsl/hlsl version:
// v = normalize(v)
// @@ Currently this is not very useful without struct initializer syntax.
normalize :: (using v: Vector3, epsilon := 0, fallback:Vector3/*=make_vector3(0, 0, 0)*/) -> Vector3 #must {
    normalize(*v, epsilon, fallback);
    return v;
} @NoProfile

normalize_or_z_axis :: inline (using v: Vector3) -> Vector3 #must {
    return normalize(v, fallback=make_vector3(0,0,1));
} @NoProfile

normalize_or_zero :: inline (using v: Vector3) -> Vector3 #must {
    return normalize(v, fallback=make_vector3(0,0,0));
} @NoProfile

unit_vector :: (v: Vector3) -> Vector3 {
    // The same as normalize_or_zero, but returning a vector.
    sq := sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
    if sq == 0 return v;

    result: Vector3 = ---;
    factor := 1.0 / sq;
    result.x = v.x * factor;
    result.y = v.y * factor;
    result.z = v.z * factor;

    return result;
}

unit_vector :: (v: Vector2) -> Vector2 {
    // The same as normalize_or_zero, but returning a vector.
    sq := sqrt(v.x*v.x + v.y*v.y);
    if sq == 0 return v;

    result: Vector2 = ---;
    factor := 1.0 / sq;
    result.x = v.x * factor;

    result.y = v.y * factor;

    return result;
}

    
normalize_or_zero :: (using v: *Vector2) -> float {
    sq := sqrt(x*x + y*y);
    if sq == 0 return sq;

    factor := 1.0 / sq;
    x *= factor;
    y *= factor;

    return sq;
} @NoProfile

rotate :: (v: *Vector2, theta: float) {
    ct := cos(theta);
    st := sin(theta);

    x := v.x * ct + v.y * -st;
    y := v.x * st + v.y * ct;

    v.x = x;
    v.y = y;
}

rotate :: (v: Vector2, theta: float) -> Vector2 {
    ct := cos(theta);
    st := sin(theta);

    r: Vector2 = ---;
    r.x = v.x * ct + v.y * -st;
    r.y = v.x * st + v.y * ct;

    return r;
}

cross :: cross_product;
cross_product :: (a: Vector3, b: Vector3) -> Vector3 {
    n: Vector3 = ---;

    n.x = a.y * b.z - a.z * b.y;
    n.y = a.z * b.x - a.x * b.z;
    n.z = a.x * b.y - a.y * b.x;

    return n;
}

rotate :: (v: Vector3, q: Quaternion) -> Vector3 {
    // For derivation, see: http://mollyrocket.com/forums/viewtopic.php?t=833&sid=3a84e00a70ccb046cfc87ac39881a3d0

    axis := make_vector3(q.x, q.y, q.z);
    t := cross_product(axis, v) * 2.0;

    return v + t * q.w + cross_product(axis, t);
}

rotate :: (v: *Vector3, q: Quaternion) {
    axis := make_vector3(q.x, q.y, q.z);
    t := cross_product(axis, <<v) * 2.0;

    vv := <<v + t * q.w + cross_product(axis, t);
    <<v = vv;
}

saturate :: (a: Vector2) -> Vector2 #must {
    r: Vector2 = ---;
    r.x = saturate(a.x);
    r.y = saturate(a.y);
    return r;
}

saturate :: (a: Vector3) -> Vector3 #must {
    r: Vector3 = ---;
    r.x = saturate(a.x);
    r.y = saturate(a.y);
    r.z = saturate(a.z);
    return r;
}

saturate :: (a: Vector4) -> Vector4 #must {
    r: Vector4 = ---;
    r.x = saturate(a.x);
    r.y = saturate(a.y);
    r.z = saturate(a.z);
    r.w = saturate(a.w);
    return r;
}

set_from_axis_and_angle :: (using q: *Quaternion, v: Vector3, theta: float) {
    axis := unit_vector(v);

    st := sin(theta * 0.5);
    ct := cos(theta * 0.5);

    x = axis.x * st;
    y = axis.y * st;
    z = axis.z * st;
    w = ct;
}

set_from_axis_and_angle :: inline (q: *Quaternion, x: float, y: float, z: float, theta: float) {
    set_from_axis_and_angle(q, make_vector3(x, y, z), theta);
}

get_axis_and_angle :: (using q: Quaternion) -> x: float64, y: float64, z: float64, theta: float64 {
    safe_w := w;
    Clamp(*safe_w, -1, 1);

    theta := acos(safe_w);

    assert(theta >= -7);
    assert(theta <= 7);

    sin_theta := sin(theta);
    theta *= 2;

    EPSILON :: 0.0001;  // @Cleanup: Think about whether this is a good value.
    if (sin_theta < EPSILON) && (sin_theta > -EPSILON) {
        return 1, 0, 0, theta;
    }

    return  x / sin_theta, y / sin_theta, z / sin_theta, theta;
}

conjugate :: (using q: Quaternion) -> Quaternion {
    r: Quaternion = ---;
    r.x = -x;
    r.y = -y;
    r.z = -z;
    r.w = w;

    return r;
}

negate :: (using q: Quaternion) -> Quaternion {
    r: Quaternion = ---;
    r.x = -x;
    r.y = -y;
    r.z = -z;
    r.w = -w;

    return r;
}

make_an_orthonormal_basis :: (x_axis: Vector3) -> (y_axis: Vector3, z_axis: Vector3) {
    cross := make_vector3(1, 1, 1);
    if x_axis.x > x_axis.y {
        if x_axis.x > x_axis.z {
            cross.x = 0;
        } else {
            cross.z = 0;
        }
    } else {
        if x_axis.y > x_axis.z {
            cross.y = 0;
        } else {
            cross.z = 0;
        }
    }

    y_axis := cross_product(cross, x_axis);
    normalize_or_z_axis(*y_axis);
    z_axis := cross_product(x_axis, y_axis);
    normalize_or_z_axis(*z_axis);

    return y_axis, z_axis;
}

make_an_orthonormal_basis :: (x_axis: Vector3, approximate_axis: Vector3) -> (y_axis: Vector3, z_axis: Vector3) {
    y_axis := cross_product(approximate_axis, x_axis);
    normalize_or_z_axis(*y_axis);
    z_axis := cross_product(x_axis, y_axis);
    normalize_or_z_axis(*z_axis);

    return y_axis, z_axis;
}


#scope_file
#if OS_WINDOWS {
    crt  :: #foreign_system_library "msvcrt";
}
#if OS_LINUX {
    crt  :: #foreign_system_library "libm";
}
#if OS_MACOSX {
   crt  :: #foreign_system_library "libc";
}
#if OS_SWITCH {
   crt  :: #foreign_system_library "nnSdk";
}

Swap :: (a: *$T, b: *T) {   // @@ Why uppercase?
    tmp := << a;
    << a = << b;
    << b = tmp;
}
