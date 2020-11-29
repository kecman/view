#load "commands.jai";

Command_Info :: struct {
    name : string;
    procedure : ([] string) -> void;
}

Console :: struct {
    history : [..]string; // different to items in that command feedback is not stored in the history
    history_position : int = -1; // -1: new line, 0..history.count-1 browsing history
    commands : [..]Command_Info;
    log : [..]string;
    input_buffer : [256]u8;
}

console : Console;

console_add_log :: (format_string: string, args: .. Any) {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);

    text := builder_to_string(*builder);

    array_add(*console.log, text);
} @PrintLike

console_clear_log :: () {
    for console.log free(it);
    array_reset(*console.log);
}

console_add_history :: (format_string: string, args: .. Any) {
    builder: String_Builder;
    defer free_buffers(*builder);

    print_to_builder(*builder, format_string, ..args);

    text := builder_to_string(*builder);

    // Insert into history. First find match and delete it so it can be pushed to the back.
    for console.history {
        if equal_nocase(text, it) {
            remove it;
            break;
        }
    }
    array_add(*console.history, text);
} @PrintLike

console_clear_history :: () {
    for console.history free(it);
    array_reset(*console.history);
}

console_execute_command :: (_command : string) {
    console.history_position = -1;

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
    for console.commands {
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
    ImGui.SetNextWindowSize(*make_vector2(520, 600), .FirstUseEver);
    ImGui.Begin("console"); // TODO if !Begin should close

    ImGui.TextWrapped("Enter 'help' for help, press TAB for text completion, press UP/DOWN to navigate history.");
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
    for item : console.log {
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

        // console passed as user data but it's a global so...
        // if (ImGui.InputText("", console.input_buffer.data, console.input_buffer.count, EnterReturnsTrue | AlwaysInsertMode)) {

        if (ImGui.InputText("", console.input_buffer.data, console.input_buffer.count, EnterReturnsTrue | CallbackCompletion | CallbackHistory, text_edit_callback, *console)) {
            defer console.input_buffer[0] = 0; // Wipe input after processing
            console_execute_command(to_string(console.input_buffer.data, str_length(console.input_buffer.data)));
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

print_location :: (loc := #caller_location) {
    print("%:%\n", loc.fully_pathed_filename, loc.line_number);
}

#import "String";

text_edit_callback :: (data : *ImGui.TextEditCallbackData) -> s32 #c_call {

    new_context : Context;
    push_context new_context {

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

                // Build a list of candidates // @TODO Use temporary allocator here
                candidates : [..]string;
                for console.commands {
                    if begins_with_nocase(it.name, current_word) {
                        array_add(*candidates, it.name);
                    }
                }

                if candidates.count == 0 {
                    // No match
                } else if candidates.count == 1 {
                    // Single match. Delete the beginning of the word and replace it entirely so we've got nice casing
                    data.DeleteChars(data, xx (word_start - data.Buf), xx (word_end - word_start));
                    data.InsertChars(data, data.CursorPos, temp_c_string(candidates[0]));
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
                        tmp := temp_c_string(candidates[0]);
                        data.InsertChars(data, data.CursorPos, tmp, tmp + cursor);
                    }

                    // List matches
                    console_add_log("# Matching commands:");
                    for candidate : candidates {
                        console_add_log("#  %", candidate);
                    }
                }
            }

            case .CallbackHistory; {

                // Example of HISTORY
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

#import "Basic";
#import "String";