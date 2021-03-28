// Things with no clear file to go in just get shoved under the carpet.jai

printv :: (a : Code, loc := #caller_location) #expand {
    get_ident_name :: (code : Code) -> string {
        root := compiler_get_nodes(code);
        assert(root.kind == .IDENT);
        ident := cast(*Code_Ident) root;
        return ident.name;
    }

#if false {
    print("%:% % = %\n", loc.fully_pathed_filename, loc.line_number, #run get_ident_name(a), #insert a);
} else {
    print("% = %\n", #run get_ident_name(a), #insert a);
}
}

printd :: (fmt : string, args : ..Any, loc := #caller_location) {
    print("%:% ", loc.fully_pathed_filename, loc.line_number);
    print(fmt, ..args);
} @PrintLike

die :: (loc := #caller_location) {
    print("exit(1) at %:%\n", loc.fully_pathed_filename, loc.line_number);
    exit(1);
}

#scope_file
#import "Compiler";