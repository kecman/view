#import "Basic";
#import "Compiler";

build :: () {

    build_options : Build_Options;

    // Disable executable generation for the current workspace, this workspace is for compile-time metaprogramming only
    build_options = get_build_options();
    build_options.output_type = Build_Output_Type.NO_OUTPUT;
    set_build_options(build_options);

    set_working_directory(#filepath);

    ws := compiler_create_workspace();
    if !ws return;

    build_options = get_build_options(ws);
    build_options.output_type = Build_Output_Type.EXECUTABLE;
    build_options.output_executable_name = "test";
    build_options.output_path = "./bin/";
    // print("%\n", build_options);
    set_build_options(build_options, ws);

    add_build_file("sandbox_002.jai", ws);
}

#run build();
