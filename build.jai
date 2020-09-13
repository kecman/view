#import "Basic";
#import "Compiler";
#import "Check";
#import "String";

build :: () {

    {
        build_options := get_build_options();
        build_options.output_type = Build_Output_Type.NO_OUTPUT;
        set_build_options(build_options);
    }

    set_working_directory(#filepath);

    w := compiler_create_workspace();
    if !w exit(1);

    command_line_arguments := compiler_get_command_line_arguments();
    if array_find(command_line_arguments, "help") {
        print("-------------------------------------\n");
        print("Build Options:\n");
        print("  debug   build debug mode (default)\n");
        print("  release build release mode\n");
        print("\n");
        print("Build Targets:\n");
        print("  view    build view target (default)\n");
        print("  test    build test target\n");
        print("-------------------------------------\n");
    }

    {
        build_options := get_build_options(w);
        build_options.output_type = Build_Output_Type.EXECUTABLE;
        if array_find(command_line_arguments, "test") {
            build_options.output_executable_name = "test";
        } else {
            build_options.output_executable_name = "view";
        }
        build_options.lazy_foreign_function_lookups = true;
        // build_options.memory_debugger = true;
        // build_options.emit_debug_info = .DWARF;
        // build_options.llvm_options.debug_options = {:string: "-g"};

        cwd :: #run get_working_directory();
        array_add(*build_options.modules_search_path_array, join(.. .[cwd, "src", "modules"], "/"));
        set_build_options(build_options, w);
    }

    compiler_begin_intercept(w);
    if array_find(command_line_arguments, "test") {
        add_build_file("src/test.jai", w);
    } else {
        add_build_file("src/main.jai", w);
    }
    add_build_string("VIEW_VERSION_STRING :: \"0.0.1\";", w); // @TODO add date here
    while true {
        message := compiler_wait_for_message();
        if !message continue;
        if message.workspace != w continue;
        if message.kind == .COMPLETE break;
        do_error_checking(message);
    }
    compiler_end_intercept(w);
}

// @Question it takes much longer if I have functions here for build debug/release???
#run {
    build();
}
