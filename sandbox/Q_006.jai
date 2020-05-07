#import "Basic";

Foo :: struct {
    i : int;
}

process_type_info :: (info : *Type_Info) {
    print("Input was %\n", <<info);
}

main :: () {
    info := type_info(Foo);
    print("%\n", <<info);
    process_type_info(info);
}