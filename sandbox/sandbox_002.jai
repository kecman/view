#import "Basic";
Debug :: #import "Debug";
#import "Sloppy_Math";

print_stack_trace :: (node: *Stack_Trace_Node) {
    while node {
        // There are two different line numbers available.
        // node.info.location has a line number, but this is the location of
        // the start of the procedure. That may be useful in some cases, but often
        // what we really want is the line number of the procedure call, which is
        // stored in node.line_number. That's what we print in this case.
        
        if node.info print("'%' at %:%\n", node.info.name, node.info.location.fully_pathed_filename, node.line_number);
        node = node.next;
    }
}

foo :: () {


    // @Question How to get information about the type of the procedure from the pointer?
    print("%\n", context.assertion_failed);
    print("%\n", type_of(context.assertion_failed));
    print("%\n", <<type_info(type_of(context.assertion_failed)));


    // print("%\n", Debug.trace_assert);

    my_logger :: (message: string, ident: string, mode: Log_Mode, data: *void) {
        print("my_logger: [%] %", ident, message);
    }
    context.logger = my_logger; // default is no-op so need to set our own
    context.assertion_failed = Debug.trace_assert;
    // print("%\n", context.assertion_failed);
    
    print_stack_trace(context.stack_trace);
    assert(false, "asserted!");
    // assert(false);

    // print("Aborting...\n");
    // Debug.abort(Debug.Exit_Code.Success); // @Question Shouldn't this print a call stack?
    // print("Aborted\n");
}

Widget :: struct {
    width : float;
    height : float : 3;
    Inner :: struct {
        detail : [3]float;
    }
}

process_struct :: (type : $T) {
    info := type_info(type);

    if info.type != Type_Info_Tag.STRUCT {
        print("This function only works on structs, got %\n", any.type.type);
    }

    t := cast(*Type_Info_Struct) any.type;

    for t.members print(" field %\n");

}

main :: () {

    print("max_of_type(%) = %\n", float, max_of_type(float)); 

    // TODO: Look at how Soa.jai works and start experimenting with making protobuf project

    // foo();

/*
    print("%\n", Widget);
    process_struct(5.2);
    process_struct(Widget);

*/

    print("DONE\n\n");
}