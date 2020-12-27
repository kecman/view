Point3 :: Vector3;

// The plane is represented as Dot(U,X) = d where U is a unit-length normal
// vector, d is the plane constant, and X is any point on the plane.  The user
// must ensure that the normal vector is unit length.
Hyperplane3 :: struct {
    a, b, c, d : float;
#place a;
    normal : Vector3 = ---;
}

// The line is represented by P+t*D, where P is an origin point, D is a
// unit-length direction vector, and t is any real number.  The user must
// ensure that D is unit length.
Line3 :: struct {
    origin : Point3;
    direction : Vector3; // must be unit length
}

// The ray is represented as P+t*D, where P is the ray origin, D is a
// unit-length direction vector, and t >= 0.  The user must ensure that D is
// unit length.
Ray3 :: struct {
    origin : Point3;
    direction : Vector3; // must be unit length
}

// The segment is represented by (1-t)*P0 + t*P1, where P0 and P1 are the
// endpoints of the segment and 0 <= t <= 1.  Some algorithms prefer a
// centered representation that is similar to how oriented bounding boxes are
// defined.  This representation is C + s*D, where C = (P0 + P1)/2 is the
// center of the segment, D = (P1 - P0)/|P1 - P0| is a unit-length direction
// vector for the segment, and |t| <= e.  The value e = |P1 - P0|/2 is the
// extent (or radius or half-length) of the segment.
Segment3 :: struct {
    start : Point3;
    end : Point3;

#place start;
    p : [2]Point3 = ---;
}

make_hyperplane3 :: (plane_normal : Vector3, point_on_plane: Vector3) -> Hyperplane3
{
    result : Hyperplane3 = ---;

    result.normal = plane_normal;
    result.d = dot(plane_normal, point_on_plane);

    return result;
}

make_normalized_hyperplane3_from_points :: (a : Point3, b : Point3, c : Point3) -> Hyperplane3
{
    result : Hyperplane3 = ---;

    normal := unit_vector(cross(c - b, a - b));
    result.normal = normal;
    result.d = -dot_product(normal, a);

    return result;
}

to_point :: (line : Line3, t : float) -> Point3
{
    return line.origin + t * line.direction;
}

to_point :: (ray : Ray3, t : float) -> Point3
{
    assert(t >= 0, "Expected t >= 0 but got t = %", t);
    return ray.origin + t * ray.direction;
}

signed_distance_point3_plane3 :: (point : Point3, plane : Hyperplane3, $compute_closest_point : bool = false) -> float, Point3
{
    signed_distance := dot(plane.normal, point) - plane.d;
    closest_point : Point3 = ---;
    #if compute_closest_point {
        closest_point = point - signed_distance * plane.normal;
    }
    return signed_distance, closest_point;
}

// test_intersect_line3_plane3 :: (line : Line3, plane : Hyperplane3) -> bool #must

find_intersect_line3_plane3 :: (line : Line3, plane : Hyperplane3) -> (intersect_count : s32 = 0 #must, parameter : float = 0)
{
    cosine := dot(line.direction, plane.normal);
    signed_distance, _ := signed_distance_point3_plane3(line.origin, plane);

    if cosine != 0. {
        // The line is not parallel to the plane, so they must intersect.
        return intersect_count = 1, parameter = -signed_distance / cosine;
    } else {
        // The line and plane are parallel.  Determine whether the line is on the plane.
        if signed_distance == 0. {
            // The line is coincident with the plane, so choose t = 0 for the parameter.
            return intersect_count = S32_MAX;
        } else {
            // The line is not on the plane.
            return;
        }
    }
}

#scope_file

test :: () {
    #import "Basic"; // @Question: ask about why this works

    print("Running test in %:%\n", #location().fully_pathed_filename, #location().line_number);

    l := Line3.{origin=.{0, 0, 0}, direction=.{0, 0, 1}};
    p := Hyperplane3.{d=10, normal=.{0, 0, 1}};
    intersect, t := find_intersect_line3_plane3(l, p);
    print("%, %, %\n", intersect, t, to_point(l, t));
}

#if 0 {
#run test();
}


dot :: dot_product;
cross :: cross_product;

#import "Math"; // @Cleanup Plane3 struct means we need to use the name Hyperplane3

// This file is based on https://github.com/davideberly/GeometricTools (Distributed under the Boost Software License, Version 1.0.)
