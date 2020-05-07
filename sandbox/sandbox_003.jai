#import "Basic";

main :: () {
    print("--- 001 -----------------\n\n");
    {
        f :: (v : $V, $n : int, $t : Type) {
            print("v is %, type %\n", v, type_of(v));
            print("n is %\n", n);
            print("t is %, info %\n", t, << type_info(t));
        }
        
        g :: (n : int) {
            print("n is %\n", n);
        }

        f("sweetling", 5, float); 
        g(42);
        g_43 := #bake_arguments g(n=43);
        g_43();
    }

    print("--- 002 -----------------\n\n");
    {
        Counter :: struct (CountType : Type = int) {
            name : string;
            count : CountType;

            print :: (c : *Counter) {
                print("Counter name %, CountType %, count %\n", c.name, c.CountType, c.count);
            } @PrintLike
        }
        
        increment_counter :: (counter : *Counter) {
            counter.count += 1;
        }

        counter : Counter;
        counter.name = "Matija";
        print("Counter \"%\" has count %\n", counter.name, counter.count);
        increment_counter(*counter);
        print("Counter \"%\" has count %\n", counter.name, counter.count);
        Counter(int).print(*counter); // works
        Counter().print(*counter); // works
        // Counter.print(*counter); // Error: Attempt to call a procedure that has unresolved polymorphism, but note the declaration counter works without having to specify the polymorphic parameters


        Foo :: struct { }

        print("%\n", #location());
        print("%:% %\n", #file, #line, << type_info(Counter));
        print("%:% %\n", #file, #line, << type_info(Counter(u8)));
        print("%:% %\n", #file, #line, << type_info(Counter(float))); // Error: same runtime size as u8???

        Counter_u8 :: Counter(u8);
        counter2 : Counter_u8;
        Counter_u8().print(*counter2);

        // counter3 : Counter();
        // counter4 : Counter(float);
    }

    print("--- 003 -------------\n\n");
    {
        matija_human := "Matija";
        fred\ _human := "Fred";
        print("%\n", matija_human);
        print("%\n", fred\ _human);
    }
}

#run main();