#import "Basic";
#import "String";
#import "Compiler";
#import "Check";

build :: () {

    build_options : Build_Options;

    build_options = get_build_options();
    build_options.output_type = Build_Output_Type.NO_OUTPUT; // This workspace is just build code
    set_build_options(build_options);

    set_working_directory(#filepath);

    ws := compiler_create_workspace();
    if !ws return;

    build_options = get_build_options(ws);
    build_options.output_type = Build_Output_Type.EXECUTABLE;
    build_options.output_executable_name = "main";
    set_build_options(build_options, ws);

    compiler_begin_intercept(ws);

    // Call add_build_string() after compiler_begin_intercept(), otherwise the compiler will
    // begin compiling file before we can start intercepting messages
    add_build_file("main.jai", ws);
    // add_build_file("input.jai", ws);

    // declarations, procedures := precompile(s, name);

    while true {
        using Compiler_Message.Kind;
        message := compiler_wait_for_message();

        if !message continue;

        do_error_checking(message);

        if message.workspace != ws continue;
        if message.kind == COMPLETE break;
        if message.kind != CODE_TYPECHECKED continue;

        tc_message := cast(*Compiler_Message_Code_Typechecked) message;
        // print("%\n", <<tc_message);

        for decl : tc_message.declarations {
            // print("%\n", <<decl);
            for expr : decl.expressions {
                _, found := find(expr.filename, "input.jai");
                if !found continue;
                // print("%\n", <<expr);
                print("                               % at %:%:%\n", expr.kind, expr.filename, expr.l0, expr.c0);

                if expr.kind == {
                    case Code_Node.Kind.IDENT;
                        expr_ident := cast(*Code_Ident) expr;
                        print("Identifier: %\n", expr_ident.name);
                }
            }
        }
    }

    compiler_end_intercept(ws);
}

#run build();
