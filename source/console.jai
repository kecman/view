#load "commands.jai";

Console :: struct {
    // history : [..]string;
    // history_position : int = -1; // -1: new line, 0..History.Size-1 browsing history.
    commands : [..]string;
    items : [..]string;
    input_buffer : [256]u8;
}

console : Console;

console_add_log :: (format_string: string, args: .. Any) {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);

    text := builder_to_string(*builder);

    array_add(*console.items, text);
} @PrintLike

console_clear_log :: () {
    for console.items {
        free(it);
    }
    array_reset(*console.items);
}

console_execute_command :: (command : string) {
    if !eat_spaces(command).count {
        return;
    }

    args : [..]string;
    {
        remainder := command;
        remainder = eat_spaces(remainder);
        while (remainder.count) {
            arg : string;
            arg, remainder = break_by_spaces(remainder);
            if arg.count {
                array_add(*args, arg);
            }
        }
    }

    found_command := false;
    for command_list {
        if it.name == args[0] {

            // Strip the procedure name from the argument list
            args.data += 1;
            args.count -= 1;

            console_add_log("%", command);
            it.procedure(args);

            found_command = true;
        }
    }

    if !found_command {
        console_add_log("# '%' : Command not found", command);
    }
}

console_draw :: () {
    ImGui.SetNextWindowSize(*make_vector2(520, 600), .FirstUseEver);
    ImGui.Begin("console"); // TODO if !Begin should close

    ImGui.TextWrapped("Enter 'HELP' for help, press TAB to use text completion.");
    ImGui.SameLine();

    if (ImGui.SmallButton("Clear")) {
         console_clear_log();
    }

    ImGui.Separator();

    footer_height_to_reserve := ImGui.GetStyle().ItemSpacing.y + ImGui.GetFrameHeightWithSpacing(); // 1 separator, 1 input text

    scrolling_region_size : ImVec2;
    scrolling_region_size.x = -footer_height_to_reserve;
    scrolling_region_size.y = -footer_height_to_reserve;
    ImGui.BeginChild("ScrollingRegion", *scrolling_region_size, false, .HorizontalScrollbar); // Leave room for 1 separator + 1 InputText
    if (ImGui.BeginPopupContextWindow()) {
        // @CompilerBug: The Selectable overload fails unless 
        bug_workaround_default_size:ImVec2;
        bug_workaround_selected:bool = false;
        if (ImGui.Selectable(temp_c_string("Clear"), bug_workaround_selected, size=*bug_workaround_default_size)) {
            console_clear_log();
        }
        ImGui.EndPopup();
    }

    ImGui.PushStyleVar(.ItemSpacing, *ImVec2.{4,1}); // Tighten spacing
    for item : console.items {
        assert(item.count != 0);
        col := ImVec4.{1., 1., 1., 1.};
        if begins_with(item, "#") {
            col = ImVec4.{1., .78, .58, 1.};
        } else if begins_with(item, "[error]") {
            col = ImVec4.{1., .4, .4, 1.};
        }
        ImGui.TextColored(*col, "%s", temp_c_string(item));
    }
    ImGui.PopStyleVar();
    ImGui.EndChild();
    ImGui.Separator();

    {
        using ImGui.InputTextFlags; // @Question this using is here due to: "Operator '|' does not work on this type. (Left type of the attempted binary operation: unary '.' dereference; right type: unary '.' dereference)"
        if (ImGui.InputText("", console.input_buffer.data, console.input_buffer.count, EnterReturnsTrue | AlwaysInsertMode)) {
            defer console.input_buffer[0] = 0; // Wipe input after processing
            console_execute_command(to_string(console.input_buffer));
        }

        // Keeping auto focus on the input box after command is entered
        if (ImGui.IsItemHovered() || ( ImGui.IsWindowFocused(.RootAndChildWindows) &&
                                      !ImGui.IsAnyItemActive()                     &&
                                      !ImGui.IsMouseClicked(0))) {
            ImGui.SetKeyboardFocusHere(-1); // Auto focus previous widget
        }
    }


    ImGui.End();
}

#scope_file

#import "Basic";
#import "String";