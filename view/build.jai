#import "Basic";
#import "Compiler";

build :: () {

    {
        build_options := get_build_options();
        build_options.output_type = Build_Output_Type.NO_OUTPUT;
        set_build_options(build_options);
    }

    set_working_directory(#filepath);

    w := compiler_create_workspace();
    if !w exit(1);

    {
        build_options := get_build_options(w);
        build_options.output_type = Build_Output_Type.EXECUTABLE;
        build_options.output_executable_name = "view";
        build_options.lazy_foreign_function_lookups = true;
        array_add(*build_options.modules_search_path_array, get_working_directory());
        set_build_options(build_options, w);
    }

    compiler_begin_intercept(w);
    add_build_file("main.jai", w);
    compiler_end_intercept(w);
}

#run build();