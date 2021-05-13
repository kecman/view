// Things with no clear file to go in just get shoved under the carpet.jai

// Returns a string in temporary storage
filetime_to_iso_date :: (filetime : u64) -> string {
    year, month, day, hour, min, sec := filetime_to_localtime(filetime);
    // example: 2007-03-01T13:00:00
    return tprint("%-%-%T%:%:%", year, formatInt(month, minimum_digits=2), formatInt(day, minimum_digits=2), formatInt(hour, minimum_digits=2), formatInt(min, minimum_digits=2), formatInt(sec, minimum_digits=2));
}

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