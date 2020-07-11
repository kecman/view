#scope_file

#import "Math";

#scope_export

#load "axis_box.jai";
#load "polyline.jai";
#load "rendering.jai";

to_radians :: (degrees : float) -> float {
    scale :: PI / 180;
    return degrees * scale;
}