#import "Basic";

// Uncommenting AAAA only: Compiles fine, but z shadows v.z, program prints "z is 98"
// Uncommenting BBBB only: "Error: Redeclaration of variable 'z'."

main :: () {
  Vec3 :: struct {
    x : float = 11;
    y : float = 222;
    z : float = 3333;
  }
  
  Vec4 :: struct {
    x : float = 11;
    y : float = 222;
    z : float = 3333;
    w : float = 44444;
  }
  
  v4 : Vec4; 
  using v4;
  
  // z : float = 98; // AAAA
  v : Vec3; 
  using v;
  // z : float = 98; // BBBB

  print("z is %\n", z);
}
