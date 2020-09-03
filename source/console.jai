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
    if !command.count return;

    console_add_log("Wowee executing: %", command);
}

console_draw :: () {
    ImGui.SetNextWindowSize(*make_vector2(520, 600), .FirstUseEver);
    ImGui.Begin("console"); // TODO if !Begin should close

    ImGui.TextWrapped("Enter 'HELP' for help, press TAB to use text completion.");

    if (ImGui.SmallButton("Add Dummy Text")) {
        console_add_log("% some text", console.items.count);
        console_add_log("some more text");
        console_add_log("display very important message here!");
    }
    ImGui.SameLine();

    if (ImGui.SmallButton("Add Dummy Error")) {
        console_add_log("[error] something went wrong");
    }
    ImGui.SameLine();

    if (ImGui.SmallButton("Clear")) {
         console_clear_log();
    }
    ImGui.SameLine();

    ImGui.Separator();

    // ImGui.PushStyleVar(.FramePadding, *ImVec2.{0,0});
    // // static ImGuiTextFilter filter;
    // // filter.Draw("Filter (\"incl,-excl\") (\"error\")", 180);
    // ImGui.PopStyleVar();
    // ImGui.Separator();

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
        col := ImVec4.{1,1,1,1}; // A better implementation may store a type per-item. For the sample let's just parse the text.
        // if (strstr(item, "[error]")) col = ImColor(1.0f,0.4f,0.4f,1.0f);
        // else if (strncmp(item, "# ", 2) == 0) col = ImColor(1.0f,0.78f,0.58f,1.0f);
        // ImGui.PushStyleColor(.Text, col);
        ImGui.TextUnformatted(temp_c_string(item));
        // ImGui.PopStyleColor();
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
        if (ImGui.IsItemHovered() || (ImGui.IsWindowFocused(.RootAndChildWindows) && !ImGui.IsAnyItemActive() && !ImGui.IsMouseClicked(0))) {
            ImGui.SetKeyboardFocusHere(-1); // Auto focus previous widget
        }
    }


    ImGui.End();
}

#scope_file

#import "Basic";
#import "String";