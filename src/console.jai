Command_Info :: struct {
    name : string;
    procedure : ([] string) -> ();
}

Console :: struct {
    history : [..]string; // different to items in that command feedback is not stored in the history
    history_position : int = -1; // -1: new line, 0..history.count-1 browsing history
    commands : [..]Command_Info;
    log : [..]string;
    input_buffer : [256]u8;
}

console_add_log :: (format_string: string, args: .. Any) {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);

    text := builder_to_string(*builder);

    array_add(*app.console.log, text);
} @PrintLike

console_clear_log :: () {
    for app.console.log free(it);
    array_reset(*app.console.log);
}

console_add_history :: (format_string: string, args: .. Any) {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);

    text := builder_to_string(*builder);

    // Insert into history. First find match and delete it so it can be pushed to the back.
    for app.console.history {
        if equal_nocase(text, it) {
            remove it;
            break;
        }
    }
    array_add(*app.console.history, text);
} @PrintLike

console_clear_history :: () {
    for app.console.history free(it);
    array_reset(*app.console.history);
}

console_execute_command :: (_command : string) {
    app.console.history_position = -1;

    command := eat_trailing_spaces(_command);
    command = eat_spaces(command);
    if !command.count {
        return;
    }

    args : [..]string;
    args.allocator = __temporary_allocator;
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
    for app.console.commands {
        if it.name == args[0] {

            // Strip the procedure name from the argument list
            args.data += 1;
            args.count -= 1;

            console_add_history("%", command);
            console_add_log("%", command);
            it.procedure(args);

            found_command = true;
            break;
        }
    }

    if !found_command {
        console_add_log("# '%' : Command not found", command);
    }
}

console_draw :: () {
    if !app.show_console_ui return;

    console_top_y := app.current_window_height * .6;
    ImGui.SetNextWindowPos(ImGui.make_ImVec2(0, xx console_top_y));
    ImGui.SetNextWindowSize(ImGui.make_ImVec2(xx app.current_window_width, xx (app.current_window_height - console_top_y)), .Always);
    ImGui.Begin("console", flags = ImGui.WindowFlags.AlwaysAutoResize | ImGui.WindowFlags.NoTitleBar); // TODO if !Begin should close

    ImGui.TextWrapped("Enter 'help' for help, press TAB for text completion, press UP/DOWN to navigate history.");

    // ImGui.SameLine();
    // if (ImGui.SmallButton("Clear")) {
    //      console_clear_log();
    // }
    ImGui.Separator();

    footer_height_to_reserve := ImGui.GetStyle().ItemSpacing.y + ImGui.GetFrameHeightWithSpacing(); // 1 separator, 1 input text

    scrolling_region_size : ImGui.ImVec2;
    scrolling_region_size.x = -footer_height_to_reserve;
    scrolling_region_size.y = -footer_height_to_reserve;
    ImGui.BeginChild("ScrollingRegion", scrolling_region_size, false, .HorizontalScrollbar); // Leave room for 1 separator + 1 InputText
    if (ImGui.BeginPopupContextWindow()) {
        if ImGui.Selectable("Clear") {
            console_clear_log();
        }
        ImGui.EndPopup();
    }

    ImGui.PushStyleVar(.ItemSpacing, ImGui.ImVec2.{4,1}); // Tighten spacing
    for item : app.console.log {
        assert(item.count != 0);
        col := ImGui.ImVec4.{1., 1., 1., 1.};
        if begins_with(item, "#") {
            col = ImGui.ImVec4.{1., .78, .58, 1.};
        } else if begins_with(item, "[error]") {
            col = ImGui.ImVec4.{1., .4, .4, 1.};
        }
        ImGui.TextColored(col, "%", item);
    }
    ImGui.PopStyleVar();
    ImGui.EndChild();
    ImGui.Separator();

    {
        using ImGui.InputTextFlags; // @Question this using is here due to: "Operator '|' does not work on this type. (Left type of the attempted binary operation: unary '.' dereference; right type: unary '.' dereference)"

        // console passed as user data but it's a global so...
        // if (ImGui.InputText("", console.input_buffer.data, console.input_buffer.count, EnterReturnsTrue | AlwaysInsertMode)) {

        ImGui.PushItemWidth(-1);
        text_input_flags :=  ImGui.InputTextFlags.EnterReturnsTrue | .CallbackCompletion | .CallbackHistory;
        if (ImGui.InputText("", app.console.input_buffer.data, app.console.input_buffer.count, text_input_flags, text_edit_callback, *app.console)) {
            defer app.console.input_buffer[0] = 0; // Wipe input after processing
            console_execute_command(to_string(app.console.input_buffer.data, str_length(app.console.input_buffer.data)));
        }
        ImGui.PopItemWidth();

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

str_length :: (x: *u8) -> int @pure {  // Copied from String.jai to avoid dependency.
    p := x;
    while << p  { p += 1; }
    return p - x;
}

print_location :: (loc := #caller_location) {
    print("%:%\n", loc.fully_pathed_filename, loc.line_number);
}

text_edit_callback :: (data : *ImGui.InputTextCallbackData) -> s32 #c_call {

    new_context : Context;
    push_context new_context {

        // @Cleanup Why does this fail? app is global so I expected we could pass null and just read it directly.
        // assert(cast(*void) data == cast(*void) *app.console);

        if data.EventFlag == {
            case .CallbackCompletion; {

                // Locate beginning of current word
                word_end := data.Buf + data.CursorPos;
                word_start := word_end;
                while word_start > data.Buf {
                    c := <<(word_start - 1);
                    if (c == #char " " || c == #char "\t" || c == #char "," || c == #char ";")
                        break;
                    word_start -= 1;
                }

                current_word := to_string(word_start, word_end - word_start);

                // @CompilerBug: Even though we have pushed a context we get an error about calling a native procedure
                // printv(#code current_word);
                // print("current_word = %\n", current_word);

                // Build a list of candidates // @TODO Use temporary allocator here
                candidates : [..]string;
                for app.console.commands {
                    if begins_with_nocase(it.name, current_word) {
                        array_add(*candidates, it.name);
                    }
                }

                if candidates.count == 0 {
                    // No match
                } else if candidates.count == 1 {
                    // Single match. Delete the beginning of the word and replace it entirely so we've got nice casing
                    data.DeleteChars(data, xx (word_start - data.Buf), xx (word_end - word_start));
                    data.InsertChars(data, data.CursorPos, candidates[0]);
                    data.InsertChars(data, data.CursorPos, " ");
                } else {
                    // Multiple matches. Complete as much as we can

                    cursor : s32 = xx (word_end - word_start);
                    while true {
                        cursor_character := to_upper(candidates[0][cursor]);

                        all_candidates_match := true;
                        for candidate, candidate_index : candidates {
                            if !all_candidates_match {
                                break;
                            }

                            if cursor == candidate.count || cursor_character != to_upper(candidate[cursor]) {
                                all_candidates_match = false;
                            }
                        }

                        if !all_candidates_match {
                            break;
                        }

                        cursor += 1;
                    }

                    if cursor > 0 {
                        data.DeleteChars(data, xx (word_start - data.Buf), xx (word_end - word_start));
                        tmp := slice(candidates[0], 0, cursor);
                        data.InsertChars(data, data.CursorPos, tmp);
                    }

                    // List matches
                    console_add_log("# Matching commands:");
                    for candidate : candidates {
                        console_add_log("#  %", candidate);
                    }
                }
            }

            case .CallbackHistory; {

                using app;

                prev_history_position := console.history_position;
                if data.EventKey == .UpArrow {
                    if console.history_position == -1 {
                        console.history_position = console.history.count - 1;
                    } else if console.history_position > 0 {
                        console.history_position -= 1;
                    }
                } else if data.EventKey == .DownArrow {
                    if console.history_position != -1 {
                        console.history_position += 1;
                        if console.history_position >= console.history.count {
                            console.history_position = -1;
                        }
                    }
                }

                // A better implementation would preserve the data on the current input line along with cursor position.
                if prev_history_position != console.history_position {

                    if console.history_position >= 0 {
                        item := console.history[console.history_position];
                        data.CursorPos = xx item.count;
                        memcpy(data.Buf, item.data, item.count);
                        data.Buf[item.count] = 0;
                        data.BufTextLen = xx item.count;
                    } else {
                        data.CursorPos = 0;
                        data.Buf[0] = 0;
                        data.BufTextLen = 0;
                    }

                    assert(str_length(data.Buf) == data.BufTextLen);

                    data.SelectionStart = data.CursorPos;
                    data.SelectionEnd = data.CursorPos;
                    data.BufDirty = true;
                }
            }
        }
    }

    return 0;
}
