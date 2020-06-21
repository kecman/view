#import "Basic";

Foo :: struct {
    a : int;
}

main :: () {
    f1 := New(Foo); 
    f1.a = 1;
    // f1 = null;

    f2 := New(Foo); 
    f2.a = 2;

    f3 := New(Foo); 
    f3.a = 3;

    foos : [..] *Foo;

    array_add(*foos, f1);
    array_add(*foos, f2);
    array_add(*foos, f3);

    for foos print("% %\n", it_index, it);

    for * foos {
        if it_index == 1 {
            <<it = null;
        }
    }

    for foos print("% % \n", it_index, it);

    array_unordered_remove_by_value(*foos, null);

    for foos print("% % \n", it_index, it);
}