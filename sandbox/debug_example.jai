#import "Basic";
Debug :: #import "Debug";

main :: () {

    Debug.attach_to_debugger();
    Debug.breakpoint();

    Datum :: struct {
        count :: 3;

        numbers : [count]int;
        strings : [count]string;
        structs : [count]Nested;

        Nested :: struct {
            a : int;
            b : int;
        }

        make :: (n : int) -> Datum {
            data : Datum;
            for 0..count-1 {
                data.numbers[it] = n;
                data.strings[it] = sprint("number is %", 10 * n + it);
                data.structs[it].a = n;
                data.structs[it].b = n;
            }
            return data;
        }
    }

    data : [..]Datum;
    array_add(*data, Datum.make(0), Datum.make(1), Datum.make(2));

    for data {
        print("%, %, %\n", it.strings[0], it.strings[1], it.strings[2]);
        // Can inspect `it` and `it_index` here
    }
}

#run main();