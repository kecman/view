#import "Basic";
#import "Compiler";
#import "Check";
#import "String";

build :: () {

    {
        // This is a build file that doesn't generate an executable
        using build_options := get_build_options();
        defer set_build_options(build_options);
        output_type = .NO_OUTPUT;
    }

    set_working_directory(#filepath);

    // Create a workspace where we will compile our actual program
    w := compiler_create_workspace();
    if !w exit(1);

    command_line_arguments := compiler_get_command_line_arguments();
    help_found    := array_find(command_line_arguments, "help");
    test_found    := array_find(command_line_arguments, "test");
    demo_found    := array_find(command_line_arguments, "demo");
    release_found := array_find(command_line_arguments, "release");
    checks_found  := array_find(command_line_arguments, "checks");
    boost_found   := array_find(command_line_arguments, "boost_on");

    if help_found {
        print(help_string);
        exit(0);
    }

    {
        using build_options := get_build_options(w);
        defer set_build_options(build_options, w);

        output_type = .EXECUTABLE;
        lazy_foreign_function_lookups = true;

        if      test_found output_executable_name = "test";
        else if demo_found output_executable_name = "demo";
        else               output_executable_name = "garage";

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

        _import_path : [..]string;
        for import_path array_add(*_import_path, it);
        array_add(*_import_path, join(CWD, "src/modules", separator="/"));
        import_path = _import_path;
    }

    {
        compiler_begin_intercept(w);
        defer compiler_end_intercept(w);

        add_build_string(version_string, w);

        if      test_found add_build_file("src/test.jai", w);
        else if demo_found add_build_file("src/demo.jai", w);
        else               add_build_file("src/main.jai", w);

        if boost_found     add_build_string("ENABLE_BOOST_POLYGON :: true;", w);
        else               add_build_string("ENABLE_BOOST_POLYGON :: false;", w);

        while true {
            message := compiler_wait_for_message();
            if !message                  continue;
            if message.workspace != w    continue;
            if message.kind == .COMPLETE break;
            do_error_checking(message);
        }
    }
}

#run build();

version_string :: #string DONE
VERSION_STRING :: "0.0.5";
DONE

help_string :: #string DONE

Build Options:
  debug      build debug mode (default)
  release    build release mode
  checks     enable array bounds checks and fatal cast and math bounds checks
  boost_on   compile with boost polygon bindings (default off since the library isn't distributed yet)

Build Targets:
  garage     build garage target (default)
  test       build test target
  demo       build demo target

DONE
