#import "Basic";

main :: () {
  // TODO: Get string name of variable?
  print("\n--- 001/002 --------------\n\n");

  {
    a : float;
    print("a = %, type %\n", a, type_of(a));
    c : float : 1234;
    print("c = %, type %\n", c, type_of(c));
    f :: () {}
    print("f = %, type %\n", f, type_of(f));

    i: s16 = xx 80000;
    // k: s16 = cast,no_check(s32) i;
    //print("i = %, type %\n", i, type_of(i));
    j : s8;
    // j = i;

    x : bool;
    print("x = %, type %, size %\n", x, type_of(x), size_of(type_of(x)));
  }

  print("\n--- 003 ----------------\n\n");
  {
    if_check :: (arg : $T) {
      b := cast(bool) arg;

      if arg {
         print("b is %, type_of(arg) is %. It should be true\n", b, type_of(arg));  
      } else {
         print("b is %, type_of(arg) is %. It should be false\n", b, type_of(arg));  
      }
    }

    if_check(0);
    if_check(1);
    if_check("what");
    if_check(-1.);
    if_check(-10000000000000.);
  }

  print("\n--- 004 ----------------\n\n");
  
  {
    {
      x : [8] int = ---;
      x[0] =  0;
      x[1] = 11;
      x[2] = 22;
      x[3] = 33;
      x[4] = 44;
      x[5] = 55;
      x[6] = 66;
      x[7] = 77;

      print("x is %\n", type_of(x));

      // for value, index : x {
      //   print("% -> %\n", index, value);
      // }

      y : [9] int = ---;
      print("type_of(y) is %, %\n", type_of(y), type_of(x) == type_of(y));
    }

    {
      a : [8] float;
      v : [] float;  

      for i : 0..7 a[i] = cast(float) i;
      print("% % ::::::::::: % %\n", a.count, a.data, type_of(a.count), type_of(a.data));

      v = a;

      print("size_of(type_of(a)) = % bytes\n", size_of(type_of(a)));
      print("size_of(type_of(v)) = % bytes\n", size_of(type_of(v)));

      print_sum :: (name : string, array : [] float) {
        sum : float;
        for value : array sum += value;
        print("sum of % array is %\n", name, sum);
      }

      print_sum("a", a);
      print_sum("v", v);


      // Adjusting the view
      print("Before adjusting the view\n\n");
      for d : v print("%\n", d);
      
      v.count -= 2;
      v.data += 2;

      print("After adjusting the view\n\n");
      for d : v print("%\n", d);

      // arrays
      static_array : [16]int;
      array_view : []int;
      dynamic_array : [..]int;
      array_add(*dynamic_array, 1,2,3,4,5,5,5,55);

      for v : dynamic_array print("%\n", v);

    }
  }

  print("\n--- 005 ----------------\n\n");

  {
    matija := "matija";

    print("matija = %, type_of(matija) = %\n", matija, type_of(matija));
    print("matija[0] = %, type_of(matija[0]) = %\n", matija[0], type_of(matija[0]));
    // print("matija[110] = %, type_of(matija[110]) = %\n", matija[110], type_of(matija[110]));

    builder: String_Builder;
    init_string_builder(*builder);

    append(*builder, "One!");
    append(*builder, "Two!");
    append(*builder, "Three!");

    s :string= builder_to_string(*builder);
    print("It is: '%'.\n", s);

    y :: "constanty";
    z := "constantz";
    //y = "hi";
    z = "hi";

    print("y=%, type_of(y)=%, z=%, type_of(z)=%\n\n", y, type_of(y), z, type_of(z));

    strlen :: (s : *u8) -> s64 {
      count := 0;
      while <<s {
        count += 1;
        s += 1;
      }
      return count;
    }


    print("strlen(\"Sailor\") is %.\n", strlen("Sailor"));
    print("strlen(\"Sailor\") is %.\n", strlen(y));
    // print("strlen(\"Sailor\") is %.\n", strlen(z));

    print("\n");
  }

  print("\n--- 006 ----------------\n\n");

  {
    Orientation :: struct {

      x : float;
      y : float;
      z : float;
    }
     
    Matija :: struct {
      age : int = 32;
      height_cm : float = 20;
      constant :: "What";
      the_constant :string = constant;
      orientation : Orientation;
      orientation.x = 1;
      orientation.y = 10;
      orientation.z = 100;
    }

    matija : Matija;

    print("matija = %\ntype_of(matija) = %\n", matija, type_of(matija));
    print("\n\n\n");
    print("size_of(matija) = %\n", size_of(type_of(matija)));

    {
      // using matija;
      // age += 1;
      z : float = 42;

      using matija.orientation;
      x *= -1;
      z *= -1;

      print("z=%\n", z);
    }

    print("matija = %\ntype_of(matija) = %\n", matija, type_of(matija));
  }

  print("\n--- 007 ----------------\n\n");

  {
    a : Type;
    print("a = %\n\n", a);
    a = int;
    print("a = %\n\n", a);

    // b : type_of(a);
    // b = 54;
    // print("b = %\n", b);
  }

  print("\n--- functions ---------\n\n");

  {
    foo :: (a : int) -> int, float {
      return a, cast(float) a*a;
    }

    i, f := foo(3);

    print("i = %, f = %\n\n", i, f);

    goo :: (a : ..int) -> int, float {
      for a print("a[%] = %\n", it_index, it);
      return a.count, cast(float) a.count;
    }

    goo(..{:int: 1,2,3,4});

    () {
      print("hello, anon\n");
    } ();

    hoo :=  () {
      print("hello, hoo\n");
    };

    hoo();

    hoo = () {
      print("NOT\n");
    };

    hoo();

    poo :: (t : $T) {
        print("From poo: t = %, type_of(T) = %\n", t, T);
    }

    poo(34);

    // boo = #bake poo(42);
    // boo();
  }

  array :: [..]int;
  if array {
    print("true");
  } else {
    print("false");
  }

    my_assertion_handler :: (loc: Source_Code_Location, message: string) {
         print("\nAssertion failed: %\n stack_trace: %\n", message, pack_stack_trace());
    }

    // The default assertion handler simply prints the source location
    // of the assertion and a message to dump to the console on stdout,
    // then calls abort(). It is pretty trivial to hook the assertion
    // handler to perform arbitrary functions. A less trivial, alternate
    // assertion handler can be observed in jai's Debug module (which,
    // among other things, dumps the current stack and spawns an
    // interactive message box).

    context.assertion_failed = my_assertion_handler;

   assert(false, "FAILED");

  print("\n\nDONE\n\n");
}

#run main();

