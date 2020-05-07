#import "Basic";

// Nothing interesting to see here...

main :: () {
    Counter :: struct (CountType : Type = u8) {
        name : string;
        count : CountType;

    }

    print :: (c : $T/Counter) {
        print("Counter name %, CountType %, count %, Type_Info %\n", c.name, c.CountType, c.count, <<type_info(type_of(<<c)));
    }
    
    {
        baked : Counter;

        baked.name = "baked";
        // Counter.print(*baked); // Error: Attempt to call a procedure that has unresolved polymorphism
    }

    {
        Broad :: Counter();

        broad : Broad;
        broad.name = "broad";
        print(*broad);
        c := *broad;
        print("Counter name %, CountType %, count %, Type_Info %\n", c.name, c.CountType, c.count, <<type_info(type_of(<<c)));
    }

    {
        Black :: Counter(u64);

        black : Black;
        black.name = "black";
        print(*black);
        c := *black;
        print("Counter name %, CountType %, count %, Type_Info %\n", c.name, c.CountType, c.count, <<type_info(type_of(<<c)));
    }

/*
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
    */
}

#run main();