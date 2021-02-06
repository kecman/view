#import "Basic";
#import "Compiler";
#import "Check";
#import "String";

version_string :: #string DONE
    VIEW_VERSION_STRING :: "0.0.1";
DONE

help_string :: #string DONE

Build Options:
  debug   build debug mode (default)
  release build release mode
  checks  enable array bounds checks and fatal cast and math bounds checks

Build Targets:
  view    build view target (default)
  test    build test target

DONE

build :: () {

    {
        using build_options := get_build_options();
        defer set_build_options(build_options);
        output_type = .NO_OUTPUT;
    }

    set_working_directory(#filepath);

    w := compiler_create_workspace();
    if !w exit(1);

    command_line_arguments := compiler_get_command_line_arguments();
    help_found    := array_find(command_line_arguments, "help");
    test_found    := array_find(command_line_arguments, "test");
    release_found := array_find(command_line_arguments, "release");
    checks_found  := array_find(command_line_arguments, "checks");

    if help_found {
        print(help_string);
        exit(0);
    }

    {
        using build_options := get_build_options(w);
        defer set_build_options(build_options, w);
        output_type = .EXECUTABLE;
        lazy_foreign_function_lookups = true;


        if test_found {
            output_executable_name = "test";
        } else {
            output_executable_name = "view";
        }

        if checks_found {
            array_bounds_check = .ON;
            cast_bounds_check  = .FATAL;
            math_bounds_check  = .FATAL;
        }

        if release_found {
            set_optimization_level(*build_options, 3, 3);
        } else {
            // memory_debugger = true;
            // llvm_options.debug_options = .["-g"];
        }

        CWD :: #run get_working_directory();
        array_add(*modules_search_path_array, join(CWD, "src/modules", separator="/"));
    }

    compiler_begin_intercept(w);
    if test_found add_build_file("src/test.jai", w);
    else          add_build_file("src/main.jai", w);
    add_build_string(version_string, w);
    while true {
        message := compiler_wait_for_message();
        if !message                  continue;
        if message.workspace != w    continue;
        if message.kind == .COMPLETE break;
        do_error_checking(message);
    }
    compiler_end_intercept(w);
}

// @Question it takes much longer if I have functions here for build debug/release???
#run {
    build();
}
