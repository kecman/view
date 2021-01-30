// Things with no clear file to go in just get shoved under the carpet.jai

printv :: (a : Code) #expand {
    get_ident_name :: (code : Code) -> string {
        root := compiler_get_nodes(code);
        assert(root.kind == .IDENT);
        ident := cast(*Code_Ident) root;
        return ident.name;
    }

    print("% = %\n", #run get_ident_name(a), #insert a);
}

die :: (loc := #caller_location) {
    print("exit(1) at %:%\n", loc.fully_pathed_filename, loc.line_number);
    exit(1);
}