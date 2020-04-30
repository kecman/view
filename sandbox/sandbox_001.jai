#import "Basic";
Debug :: #import "Debug";

main :: () {
     print("\n\n");
      
     print("--- enums -------------\n\n");


     {
         Thing :: enum { A; B; C; }

         t : Thing = Thing.B;

         if #complete t == {
            case Thing.A;
                 print("A\n");
            case Thing.B;
                 print("B\n");
            case Thing.C;
                 print("C\n");
         }
     }

     print("--- iterators -----------\n\n");
      
     {
          Vec3 :: struct {
               x : float;
               y : float;
               z : float;

               #place x;
               coords : [3]float;

               make :: (x : float, y : float, z : float) -> Vec3 {
                    v : Vec3;
                    v.x = x;
                    v.y = y;
                    v.z = z;
                    return v;
               }
          }

          polyline : [..]Vec3; // @HowTo How to make a Polyline alias for [..]Vec3?
          array_add(*polyline, Vec3.make(0, 10, 20));
          array_add(*polyline, Vec3.make(1, 11, 21));
          array_add(*polyline, Vec3.make(2, 12, 22));

          for *polyline {
               print("[%] -> %\n\n", it_index, <<it);
               Debug.attach_to_debugger();
               Debug.breakpoint();
               it.z *= 2;
          }

          for *polyline print("[%] -> %\n\n", it_index, <<it);
     }
}