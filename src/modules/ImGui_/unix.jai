ImGui :: struct {

    allocate_per_frame :: () { /*...*/ }
    per_frame_storage : Temporary_Storage;
    
    ID :: u32;       // unique ID used by widgets (typically hashed from a stack of string)

    TextEditCallback :: #type (data: *TextEditCallbackData) -> s32 #c_call;
    SizeConstraintCallback :: #type (data: *SizeConstraintCallbackData) #c_call;

    //v2zero :: make_vector2(0, 0);
    //v4zero :: make_vector4(0, 0, 0, 0);
    //v2one :: make_vector2(1, 1);
    //v4one :: make_vector4(1, 1, 1, 1);


    // Main
    GetIO       :: () -> *IO #foreign imgui "_ZN5ImGui5GetIOEv";
    GetStyle    :: () -> *Style #foreign imgui "_ZN5ImGui8GetStyleEv";
    GetDrawData :: () -> *ImDrawData #foreign imgui "_ZN5ImGui11GetDrawDataEv";
    _NewFrame :: () #foreign imgui "_ZN5ImGui8NewFrameEv";
    Render    :: () #foreign imgui "_ZN5ImGui6RenderEv";
    _EndFrame :: () #foreign imgui "_ZN5ImGui8EndFrameEv";
    Shutdown  :: () #foreign imgui "_ZN5ImGui8ShutdownEv";

    NewFrame  :: () {
        // @@ Allocate temporary storage, if not done yet.
        _NewFrame();
    }
    EndFrame :: () {
        _EndFrame();
        // @@ Reset tempoary storage.
    }

    #if IMGUI_ENABLE_DEMO { // IC: These functions are only available if imgui_demo.cpp is compiled into the dll.
        // Demo, Debug, Informations
        ShowDemoWindow :: (p_open: *bool = null) #foreign imgui "_ZN5ImGui14ShowDemoWindowEPb";
        ShowMetricsWindow :: (p_open: *bool = null) #foreign imgui "_ZN5ImGui17ShowMetricsWindowEPb";
        ShowStyleEditor :: (ref: *Style = null) #foreign imgui "_ZN5ImGui15ShowStyleEditorEP10ImGuiStyle";
        ShowStyleSelector :: (label: *u8) -> bool #foreign imgui "_ZN5ImGui17ShowStyleSelectorEPKc";
        ShowFontSelector :: (label: *u8) #foreign imgui "_ZN5ImGui16ShowFontSelectorEPKc"
        ShowUserGuide :: () #foreign imgui "_ZN5ImGui13ShowUserGuideEv";
    }    

    // Window
    Begin :: (label: *u8, p_open: *bool = null, flags: WindowFlags = 0) -> bool #foreign imgui "_ZN5ImGui5BeginEPKcPbi";
    End :: () #foreign imgui "_ZN5ImGui3EndEv";
    BeginChild :: (str_id: *u8, size:*ImVec2/*= *v2zero*/, border := false, extra_flags: WindowFlags=0) -> bool #foreign imgui "_ZN5ImGui10BeginChildEPKcRK6ImVec2bi";
    BeginChild :: (id: ID, size:*ImVec2/*= *v2zero*/, border := false, extra_flags: WindowFlags=0) -> bool #foreign imgui "_ZN5ImGui10BeginChildEjRK6ImVec2bi";
    EndChild :: () #foreign imgui "_ZN5ImGui8EndChildEv";
    GetContentRegionMax :: () -> Vector2 #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui19GetContentRegionMaxEv";
    GetContentRegionAvail :: () -> Vector2 #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui21GetContentRegionAvailEv";
    GetContentRegionAvailWidth :: () -> float #foreign imgui "_ZN5ImGui26GetContentRegionAvailWidthEv";
    GetWindowContentRegionMin :: () -> Vector2 #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui25GetWindowContentRegionMinEv";
    GetWindowContentRegionMax :: () -> Vector2 #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui25GetWindowContentRegionMaxEv";
    GetWindowContentRegionWidth :: () -> float #foreign imgui "_ZN5ImGui27GetWindowContentRegionWidthEv";
    GetWindowDrawList :: () -> ImDrawList #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui17GetWindowDrawListEv";
    GetWindowPos :: () -> Vector2 #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui12GetWindowPosEv";
    GetWindowSize :: () -> Vector2 #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui13GetWindowSizeEv";
    GetWindowWidth :: () -> float #foreign imgui "_ZN5ImGui14GetWindowWidthEv";
    GetWindowHeight :: () -> float #foreign imgui "_ZN5ImGui15GetWindowHeightEv";
    IsWindowCollapsed :: () -> bool #foreign imgui "_ZN5ImGui17IsWindowCollapsedEv";
    IsWindowAppearing :: () -> bool #foreign imgui "_ZN5ImGui17IsWindowAppearingEv";
    SetWindowFontScale :: (scale: float) #foreign imgui "_ZN5ImGui18SetWindowFontScaleEf";

    SetNextWindowPos :: (pos: *ImVec2, cond: Cond = 0, pivot: *ImVec2/*= ImVec2(0,0)*/) #foreign imgui "_ZN5ImGui16SetNextWindowPosERK6ImVec2iS2_"; // set next window position. call before Begin(). use pivot=(0.5f,0.5f) to center on given point, etc.
    SetNextWindowSize :: (size: *ImVec2, cond: Cond = 0) #foreign imgui "_ZN5ImGui17SetNextWindowSizeERK6ImVec2i";                                // set next window size. set axis to 0.0f to force an auto-fit on this axis. call before Begin()
    //SetNextWindowSizeConstraints :: (size_min: *ImVec2, size_max: *ImVec2, custom_callback: SizeConstraintCallback = null, custom_callback_data: *void = null)  #foreign imgui "?SetNextWindowSizeConstraints@ImGui@@YAXAEBUImVec2@@0P6AXPEAUImGuiSizeConstraintCallbackData@@@ZPEAX@Z"; // set next window size limits. use -1,-1 on either X/Y axis to preserve the current size. Use callback to apply non-trivial programmatic constraints.
    SetNextWindowContentSize :: (size: *ImVec2) #foreign imgui "_ZN5ImGui24SetNextWindowContentSizeERK6ImVec2";                                        // set next window content size (~ enforce the range of scrollbars). not including window decorations (title bar, menu bar, etc.). set an axis to 0.0f to leave it automatic. call before Begin()
    SetNextWindowCollapsed :: (collapsed: bool, cond: Cond = 0) #foreign imgui "_ZN5ImGui22SetNextWindowCollapsedEbi";                              // set next window collapsed state. call before Begin()
    SetNextWindowFocus :: () #foreign imgui "_ZN5ImGui18SetNextWindowFocusEv";                                                                             // set next window to be focused / front-most. call before Begin()
    SetWindowPos :: (pos: *ImVec2, cond: Cond = 0) #foreign imgui "_ZN5ImGui12SetWindowPosERK6ImVec2i";                                          // (not recommended) set current window position - call within Begin()/End(). prefer using SetNextWindowPos(), as this may incur tearing and side-effects.
    SetWindowSize :: (size: *ImVec2, cond: Cond = 0) #foreign imgui "_ZN5ImGui13SetWindowSizeERK6ImVec2i"; // 35                                        // (not recommended) set current window size - call within Begin()/End(). set to ImVec2(0,0) to force an auto-fit. prefer using SetNextWindowSize(), as this may incur tearing and minor side-effects.    
    SetWindowCollapsed :: (collapsed: bool, cond: Cond = 0) #foreign imgui "_ZN5ImGui18SetWindowCollapsedEbi";                                      // (not recommended) set current window collapsed state. prefer using SetNextWindowCollapsed().
    SetWindowFocus :: () #foreign imgui "_ZN5ImGui14SetWindowFocusEv";                                                                                     // (not recommended) set current window to be focused / front-most. prefer using SetNextWindowFocus().
    SetWindowPos :: (name: *u8, pos: *ImVec2, cond: Cond = 0) #foreign imgui "_ZN5ImGui12SetWindowPosEPKcRK6ImVec2i";                            // set named window position.
    SetWindowSize :: (name: *u8, size: *ImVec2, cond: Cond = 0) #foreign imgui "_ZN5ImGui13SetWindowSizeEPKcRK6ImVec2i"; // 741                         // set named window size. set axis to 0.0f to force an auto-fit on this axis.
    SetWindowCollapsed :: (name: *u8, collapsed: bool, cond: Cond = 0) #foreign imgui "_ZN5ImGui18SetWindowCollapsedEPKcbi";                       // set named window collapsed state
    SetWindowFocus :: (name: *u8) #foreign imgui "_ZN5ImGui14SetWindowFocusEv";                                                                        // set named window to be focused / front-most. use NULL to remove focus.

    // @@ Add all functions.

    // IMGUI_API float         GetScrollX();                                                       // get scrolling amount [0..GetScrollMaxX()]
    // IMGUI_API float         GetScrollY();                                                       // get scrolling amount [0..GetScrollMaxY()]
    // IMGUI_API float         GetScrollMaxX();                                                    // get maximum scrolling amount ~~ ContentSize.X - WindowSize.X
    // IMGUI_API float         GetScrollMaxY();                                                    // get maximum scrolling amount ~~ ContentSize.Y - WindowSize.Y
    // IMGUI_API void          SetScrollX(float scroll_x);                                         // set scrolling amount [0..GetScrollMaxX()]
    // IMGUI_API void          SetScrollY(float scroll_y);                                         // set scrolling amount [0..GetScrollMaxY()]
    // IMGUI_API void          SetScrollHere(float center_y_ratio = 0.5f);                         // adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
    // IMGUI_API void          SetScrollFromPosY(float pos_y, float center_y_ratio = 0.5f);        // adjust scrolling amount to make given position valid. use GetCursorPos() or GetCursorStartPos()+offset to get valid positions.
    // IMGUI_API void          SetStateStorage(ImGuiStorage* tree);                                // replace tree state storage with our own (if you want to manipulate it yourself, typically clear subsection of it)
    // IMGUI_API ImGuiStorage* GetStateStorage();

    // Parameters stacks (shared)
    // IMGUI_API void          PushFont(ImFont* font);                                             // use NULL as a shortcut to push default font
    // IMGUI_API void          PopFont();
    PushStyleColor :: (idx : ImGuiCol, col : ImU32) #foreign imgui "_ZN5ImGui14PushStyleColorEij";
    PushStyleColor :: (idx : ImGuiCol, col : *ImVec4) #foreign imgui "_ZN5ImGui14PushStyleColorEiRK6ImVec4";
    PopStyleColor :: (count : s32 = 1) #foreign imgui "_ZN5ImGui13PopStyleColorEi";
    PushStyleVar :: (idx : StyleVar, val : float) #foreign imgui "_ZN5ImGui12PushStyleVarEif";
    PushStyleVar :: (idx : StyleVar, val : *ImVec2) #foreign imgui "_ZN5ImGui12PushStyleVarEiRK6ImVec2";
    PopStyleVar :: (count : s32 = 1) #foreign imgui "_ZN5ImGui11PopStyleVarEi";
    // IMGUI_API const ImVec4& GetStyleColorVec4(ImGuiCol idx);                                    // retrieve style color as stored in ImGuiStyle structure. use to feed back into PushStyleColor(), otherwhise use GetColorU32() to get style color + style alpha.
    // IMGUI_API ImFont*       GetFont();                                                          // get current font
    // IMGUI_API float         GetFontSize();                                                      // get current font size (= height in pixels) of current font with current scale applied
    // IMGUI_API ImVec2        GetFontTexUvWhitePixel();                                           // get UV coordinate for a while pixel, useful to draw custom shapes via the ImDrawList API
    // IMGUI_API ImU32         GetColorU32(ImGuiCol idx, float alpha_mul = 1.0f);                  // retrieve given style color with style alpha applied and optional extra alpha multiplier
    // IMGUI_API ImU32         GetColorU32(const ImVec4& col);                                     // retrieve given color with style alpha applied
    // IMGUI_API ImU32         GetColorU32(ImU32 col);                                             // retrieve given color with style alpha applied

    // Parameters stacks (current window)
    PushItemWidth :: (item_width : float) #foreign imgui "_ZN5ImGui13PushItemWidthEf";             // width of items for the common item+label case, pixels. 0.0f = default to ~2/3 of windows width, >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -1.0f always align width to the right side)
    PopItemWidth :: () #foreign imgui "_ZN5ImGui12PopItemWidthEv";
    // IMGUI_API float         CalcItemWidth();                                                    // width of item given pushed settings and current cursor position
    // IMGUI_API void          PushTextWrapPos(float wrap_pos_x = 0.0f);                           // word-wrapping for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space
    // IMGUI_API void          PopTextWrapPos();
    // IMGUI_API void          PushAllowKeyboardFocus(bool allow_keyboard_focus);                  // allow focusing using TAB/Shift-TAB, enabled by default but you can disable it for certain widgets
    // IMGUI_API void          PopAllowKeyboardFocus();
    // IMGUI_API void          PushButtonRepeat(bool repeat);                                      // in 'repeat' mode, Button*() functions return repeated true in a typematic manner (using io.KeyRepeatDelay/io.KeyRepeatRate setting). Note that you can call IsItemActive() after any Button() to tell if the button is held in the current frame.
    // IMGUI_API void          PopButtonRepeat();

    // Cursor / Layout
    Separator :: () #foreign imgui "_ZN5ImGui9SeparatorEv";                                                        // separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
    SameLine :: (pos_x : float = 0, spacing_w : float = -1) #foreign imgui "_ZN5ImGui8SameLineEff" // call between widgets or groups to layout them horizontally
    NewLine :: () #foreign imgui "_ZN5ImGui7NewLineEv";                                                          // undo a SameLine()
    Spacing :: () #foreign imgui "_ZN5ImGui7SpacingEv";                                                          // add vertical spacing
    // IMGUI_API void          Dummy(const ImVec2& size);                                          // add a dummy item of given size
    // IMGUI_API void          Indent(float indent_w = 0.0f);                                      // move content position toward the right, by style.IndentSpacing or indent_w if != 0
    // IMGUI_API void          Unindent(float indent_w = 0.0f);                                    // move content position back to the left, by style.IndentSpacing or indent_w if != 0
    BeginGroup :: () #foreign imgui "_ZN5ImGui10BeginGroupEv";                                                       // lock horizontal starting position + capture group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
    EndGroup :: () #foreign imgui "_ZN5ImGui8EndGroupEv";
    // IMGUI_API ImVec2        GetCursorPos();                                                     // cursor position is relative to window position
    // IMGUI_API float         GetCursorPosX();                                                    // "
    // IMGUI_API float         GetCursorPosY();                                                    // "
    // IMGUI_API void          SetCursorPos(const ImVec2& local_pos);                              // "
    // IMGUI_API void          SetCursorPosX(float x);                                             // "
    // IMGUI_API void          SetCursorPosY(float y);                                             // "
    // IMGUI_API ImVec2        GetCursorStartPos();                                                // initial cursor position
    // IMGUI_API ImVec2        GetCursorScreenPos();                                               // cursor position in absolute screen coordinates [0..io.DisplaySize] (useful to work with ImDrawList API)
    // IMGUI_API void          SetCursorScreenPos(const ImVec2& pos);                              // cursor position in absolute screen coordinates [0..io.DisplaySize]
    // IMGUI_API void          AlignTextToFramePadding();                                          // vertically align/lower upcoming text to FramePadding.y so that it will aligns to upcoming widgets (call if you have text on a line before regular widgets)
    // IMGUI_API float         GetTextLineHeight();                                                // ~ FontSize
    // IMGUI_API float         GetTextLineHeightWithSpacing();                                     // ~ FontSize + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
    GetFrameHeight :: () -> float #foreign imgui "_ZN5ImGui14GetFrameHeightEv";                    // ~ FontSize + style.FramePadding.y * 2
    GetFrameHeightWithSpacing :: () -> float #foreign imgui "_ZN5ImGui25GetFrameHeightWithSpacingEv"; // ~ FontSize + style.FramePadding.y * 2 + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)

    // Columns
    // You can also use SameLine(pos_x) for simplified columns. The columns API is still work-in-progress and rather lacking.
    Columns :: (count : s32 = 1, id : *u8 = null, border : bool = true) -> () #foreign imgui "_ZN5ImGui7ColumnsEiPKcb";
    NextColumn :: () -> () #foreign imgui "_ZN5ImGui10NextColumnEv";                               // next column, defaults to current row or next row if the current row is finished
    // IMGUI_API int           GetColumnIndex();                                                   // get current column index
    // IMGUI_API float         GetColumnWidth(int column_index = -1);                              // get column width (in pixels). pass -1 to use current column
    SetColumnWidth :: (column_index : s32, width : float) -> () #foreign imgui "_ZN5ImGui14SetColumnWidthEif" // set column width (in pixels). pass -1 to use current column
    // IMGUI_API float         GetColumnOffset(int column_index = -1);                             // get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
    // IMGUI_API void          SetColumnOffset(int column_index, float offset_x);                  // set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
    // IMGUI_API int           GetColumnsCount();

    // ID scopes
    // If you are creating widgets in a loop you most likely want to push a unique identifier (e.g. object pointer, loop index) so ImGui can differentiate them.
    // You can also use the "##foobar" syntax within widget label to distinguish them from each others. Read "A primer on the use of labels/IDs" in the FAQ for more details.
    // IMGUI_API void          PushID(const char* str_id);                                         // push identifier into the ID stack. IDs are hash of the entire stack!
    // IMGUI_API void          PushID(const char* str_id_begin, const char* str_id_end);
    // IMGUI_API void          PushID(const void* ptr_id);
    // IMGUI_API void          PushID(int int_id);
    // IMGUI_API void          PopID();
    // IMGUI_API ImGuiID       GetID(const char* str_id);                                          // calculate unique ID (hash of whole ID stack + given parameter). e.g. if you want to query into ImGuiStorage yourself
    // IMGUI_API ImGuiID       GetID(const char* str_id_begin, const char* str_id_end);
    // IMGUI_API ImGuiID       GetID(const void* ptr_id);

    // Widgets: Text
    TextUnformatted :: (text: *u8, text_end: *u8 = null) #foreign imgui "_ZN5ImGui15TextUnformattedEPKcS1_"; // raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
    Text :: (fmt: *u8, args: .. Any) #foreign imgui "_ZN5ImGui4TextEPKcz"; // 760                                                // simple formatted text
    TextColored :: (col: *Vector4, fmt: *u8, args: .. Any) #foreign imgui "_ZN5ImGui11TextColoredERK6ImVec4PKcz"; // 218                          // shortcut for PushStyleColor(ImGuiCol_Text, col); Text(fmt, ...); PopStyleColor();
    TextDisabled :: (fmt: *u8, args: .. Any) #foreign imgui "_ZN5ImGui12TextDisabledEPKcz"; // 699                                        // shortcut for PushStyleColor(ImGuiCol_Text, style.Colors[ImGuiCol_TextDisabled]); Text(fmt, ...); PopStyleColor();
    TextWrapped :: (fmt: *u8, args: .. Any) #foreign imgui "_ZN5ImGui11TextWrappedEPKcz";  // shortcut for PushTextWrapPos(0.0f); Text(fmt, ...); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
    // void          LabelText(const char* label, const char* fmt, ...)             IM_FMTARGS(2); // display text+label aligned the same way as value+label widgets
    // void          BulletText(const char* fmt, ...)                               IM_FMTARGS(1); // shortcut for Bullet()+Text()
    Bullet :: () #foreign imgui "_ZN5ImGui6BulletEv"; // 328                                                                    // draw a small circle and keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses

    Text :: (fmt: string, args: .. Any) {
        text := tprint(fmt, ..args);
        TextUnformatted(text.data, text.data+text.count);
    }

    TextDisabled :: (fmt: string, args: .. Any) {
        text := tprintz(fmt, ..args);    // Note, tprintz appends \0 at the end.
        TextDisabled(text.data);
    }


    // Widgets: Main
    Button :: (label: *u8, size: *ImVec2/*= *v2zero*/) -> bool #foreign imgui "_ZN5ImGui6ButtonEPKcRK6ImVec2"; // 1225            // button
    SmallButton :: (label: *u8) -> bool #foreign imgui "_ZN5ImGui11SmallButtonEPKc"; // 144                                        // button with FramePadding=(0,0) to easily embed within text
    InvisibleButton :: (str_id: *u8, size: *ImVec2) -> bool #foreign imgui "_ZN5ImGui15InvisibleButtonEPKcRK6ImVec2"; // 376    // button behavior without the visuals, useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
    Image :: (user_texture_id: ImTextureID, size:*ImVec2, uv0:*ImVec2/*=*v2zero*/, uv1:*ImVec2/*=(1,1)*/, tint_col:*ImVec4/*=(1,1,1,1)*/, border_col:*ImVec4/*=(0,0,0,0)*/) #foreign imgui "_ZN5ImGui5ImageEPvRK6ImVec2S3_S3_RK6ImVec4S6_"; // 438
    ImageButton :: (user_texture_id: ImTextureID, size:*ImVec2, uv0:*ImVec2/*=*v2zero*/, uv1:*ImVec2/*=(1,1)*/, frame_padding:s32=-1, bg_col:*ImVec4/*=(0,0,0,0)*/, tint_col:*ImVec4/*=(1,1,1,1)*/) -> bool #foreign imgui "_ZN5ImGui11ImageButtonEPvRK6ImVec2S3_S3_iRK6ImVec4S6_"; // 263    // <0 frame_padding uses default frame padding settings. 0 for no padding
    Checkbox :: (label: *u8, v: *bool) -> bool #foreign imgui "_ZN5ImGui8CheckboxEPKcPb"; // 511
    CheckboxFlags :: (label: *u8, flags: *u32, flags_value: u32) -> bool #foreign imgui "_ZN5ImGui13CheckboxFlagsEPKcPjj"; // 1186
    RadioButton :: (label: *u8, active: bool) -> bool #foreign imgui "_ZN5ImGui11RadioButtonEPKcb"; // 468
    RadioButton :: (label: *u8, v: *s32, v_button: s32) -> bool #foreign imgui "_ZN5ImGui11RadioButtonEPKcPii"; // 332
    //PlotLines :: (label: *u8, const float* values, int values_count, int values_offset = 0, overlay_text: *u8 = null, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0,0), int stride = sizeof(float));
    //PlotLines :: (label: *u8, float (*values_getter)(void* data, int idx), void* data, int values_count, int values_offset = 0, overlay_text: *u8 = null, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0,0));
    //PlotHistogram :: (label: *u8, const float* values, int values_count, int values_offset = 0, overlay_text: *u8 = null, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0,0), int stride = sizeof(float));
    //PlotHistogram :: (label: *u8, float (*values_getter)(void* data, int idx), void* data, int values_count, int values_offset = 0, overlay_text: *u8 = null, float scale_min = FLT_MAX, float scale_max = FLT_MAX, ImVec2 graph_size = ImVec2(0,0));
    ProgressBar :: (fraction: float, size_arg: *ImVec2 /*= ImVec2(-1,0)*/, overlay: *u8 = null) #foreign imgui "_ZN5ImGui11ProgressBarEfRK6ImVec2PKc"; // 810

    // Widgets: Combo Box
    // The new BeginCombo()/EndCombo() api allows you to manage your contents and selection state however you want it. 
    // The old Combo() api are helpers over BeginCombo()/EndCombo() which are kept available for convenience purpose.
    BeginCombo :: (label: *u8, preview_value: *u8, flags:ComboFlags=0) -> bool #foreign imgui "_ZN5ImGui10BeginComboEPKcS1_i"; // 1056
    EndCombo :: () #foreign imgui "_ZN5ImGui8EndComboEv"; // 507
    //Combo :: (label: *u8, current_item: *s32, items: **u8, items_count: s32, popup_max_height_in_items:s32=-1) -> bool #foreign imgui "?Combo@ImGui@@YA_NPEBDPEAHQEBQEBDHH@Z";
    Combo :: (label: *u8, current_item: *s32, items_separated_by_zeros: *u8, popup_max_height_in_items:s32=-1) -> bool #foreign imgui "_ZN5ImGui5ComboEPKcPiPKS1_ii"; // 1269      // Separate items with \0 within a string, end item-list with \0\0. e.g. "One\0Two\0Three\0"
    // Combo :: (label: *u8, current_item: *s32, bool(*items_getter)(void* data, int idx, const char** out_text), data:*void, items_count:s32, popup_max_height_in_items:s32=-1) -> bool #foreign imgui "?Combo@ImGui@@YA_NPEBDPEAHP6A_NPEAXHPEAPEBD@Z2HH@Z";

    DEFAULT_DISPLAY_FORMAT_FLOAT :: "%.3f";
    DEFAULT_DISPLAY_FORMAT_INT   :: "%d";

    // Widgets: Drags (tip: ctrl+click on a drag box to input with keyboard. manually input values aren't clamped, can go off-bounds)
    // For all the Float2/Float3/Float4/Int2/Int3/Int4 versions of every functions, note that a 'float v[X]' function argument is the same as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible. You can pass address of your first element out of a contiguous set, e.g. &myvector.x
    DragFloat  :: (label: *u8, v:*float, v_speed:=1.0, v_min:=0.0, v_max:=0.0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power:=1.0) -> bool #foreign imgui "_ZN5ImGui9DragFloatEPKcPffffS1_f"; // 187     // If v_min >= v_max we have no bound
    DragFloat2 :: (label: *u8, v:*[2]float, v_speed:=1.0, v_min:=0.0, v_max:=0.0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power:=1.0) -> bool #foreign imgui "_ZN5ImGui10DragFloat2EPKcPffffS1_f"; // 92
    DragFloat3 :: (label: *u8, v:*[3]float, v_speed:=1.0, v_min:=0.0, v_max:=0.0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power:=1.0) -> bool #foreign imgui "_ZN5ImGui10DragFloat3EPKcPffffS1_f"; // 601
    DragFloat4 :: (label: *u8, v:*[4]float, v_speed:=1.0, v_min:=0.0, v_max:=0.0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power:=1.0) -> bool #foreign imgui "_ZN5ImGui10DragFloat4EPKcPffffS1_f"; // 1091
    DragFloatRange2 :: (label: *u8, v_current_min: *float, v_current_max:*float, v_speed:=1.0, v_min:=0.0, v_max:=0.0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, display_format_max: *u8 = null, power:=1.0) -> bool #foreign imgui "_ZN5ImGui15DragFloatRange2EPKcPfS2_fffS1_S1_f"; // 974
    DragInt  :: (label: *u8, v:*s32,   v_speed:float=1, v_min:s32=0, v_max:s32=0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_INT) -> bool #foreign imgui "_ZN5ImGui7DragIntEPKcPifiiS1_"; // 95                                       // If v_min >= v_max we have no bound
    DragInt2 :: (label: *u8, v:*[2]s32, v_speed:float=1, v_min:s32=0, v_max:s32=0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_INT) -> bool #foreign imgui "_ZN5ImGui8DragInt2EPKcPifiiS1_"; // 585
    DragInt3 :: (label: *u8, v:*[3]s32, v_speed:float=1, v_min:s32=0, v_max:s32=0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_INT) -> bool #foreign imgui "_ZN5ImGui8DragInt3EPKcPifiiS1_"; // 784
    DragInt4 :: (label: *u8, v:*[4]s32, v_speed:float=1, v_min:s32=0, v_max:s32=0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_INT) -> bool #foreign imgui "_ZN5ImGui8DragInt4EPKcPifiiS1_"; // 987
    DragIntRange2 :: (label: *u8, v_current_min:*s32, v_current_max:*s32, v_speed:float=1, v_min:s32=0, v_max:s32=0, display_format:*u8=DEFAULT_DISPLAY_FORMAT_INT, display_format_max: *u8 = null) -> bool#foreign imgui "_ZN5ImGui13DragIntRange2EPKcPiS2_fiiS1_S1_"; // 436

    // Widgets: Input with Keyboard
    InputText :: (label: *u8, buf: *u8, buf_size: u64, flags: InputTextFlags = 0, callback: TextEditCallback = null, user_data: *void = null) -> bool #foreign imgui "_ZN5ImGui9InputTextEPKcPcmiPFiP25ImGuiTextEditCallbackDataEPv";
    InputTextMultiline :: (label: *u8, buf: *u8, buf_size: u64, size:*ImVec2/*=(0,0)*/, flags:InputTextFlags=0, callback:TextEditCallback=null, user_data:*void=null) -> bool #foreign imgui "_ZN5ImGui18InputTextMultilineEPKcPcmRK6ImVec2iPFiP25ImGuiTextEditCallbackDataEPv";
    InputFloat :: (label: *u8, v:*float, step:float=0, step_fast:float=0, decimal_precision:s32=-1, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui10InputFloatEPKcPfffii";
    InputFloat2 :: (label: *u8, v:*[2]float, decimal_precision:s32=-1, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui11InputFloat2EPKcPfii";
    InputFloat3 :: (label: *u8, v:*[3]float, decimal_precision:s32=-1, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui11InputFloat3EPKcPfii";
    InputFloat4 :: (label: *u8, v:*[4]float, decimal_precision:s32=-1, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui11InputFloat4EPKcPfii";
    InputInt :: (label: *u8, v:*s32, step:s32=1, step_fast:s32=100, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui8InputIntEPKcPiiii";
    InputInt2 :: (label: *u8, v:*[2]s32, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui9InputInt2EPKcPii";
    InputInt3 :: (label: *u8, v:*[3]s32, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui9InputInt3EPKcPii";
    InputInt4 :: (label: *u8, v:*[4]s32, extra_flags:InputTextFlags=0) -> bool #foreign imgui "_ZN5ImGui9InputInt4EPKcPii";

    // Widgets: Sliders (tip: ctrl+click on a slider to input with keyboard. manually input values aren't clamped, can go off-bounds)
    SliderFloat :: (label: *u8, v:*float, v_min: float, v_max: float, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power: float=1.0) -> bool #foreign imgui "_ZN5ImGui11SliderFloatEPKcPfffS1_f";     // adjust display_format to decorate the value with a prefix or a suffix for in-slider labels or unit display. Use power!=1.0 for logarithmic sliders
    SliderFloat2 :: (label: *u8, v:*[2]float, v_min: float, v_max: float, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power: float=1.0) -> bool #foreign imgui "_ZN5ImGui12SliderFloat2EPKcPfffS1_f";
    SliderFloat3 :: (label: *u8, v:*[3]float, v_min: float, v_max: float, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power: float=1.0) -> bool #foreign imgui "_ZN5ImGui12SliderFloat3EPKcPfffS1_f";
    SliderFloat4 :: (label: *u8, v:*[4]float, v_min: float, v_max: float, display_format:*u8=DEFAULT_DISPLAY_FORMAT_FLOAT, power: float=1.0) -> bool #foreign imgui "_ZN5ImGui12SliderFloat4EPKcPfffS1_f";
    // IMGUI_API bool          SliderAngle(const char* label, float* v_rad, float v_degrees_min = -360.0f, float v_degrees_max = +360.0f);
    // IMGUI_API bool          SliderInt(const char* label, int* v, int v_min, int v_max, const char* display_format = "%.0f");
    // IMGUI_API bool          SliderInt2(const char* label, int v[2], int v_min, int v_max, const char* display_format = "%.0f");
    // IMGUI_API bool          SliderInt3(const char* label, int v[3], int v_min, int v_max, const char* display_format = "%.0f");
    // IMGUI_API bool          SliderInt4(const char* label, int v[4], int v_min, int v_max, const char* display_format = "%.0f");
    // IMGUI_API bool          VSliderFloat(const char* label, const ImVec2& size, float* v, float v_min, float v_max, const char* display_format = "%.3f", float power = 1.0f);
    // IMGUI_API bool          VSliderInt(const char* label, const ImVec2& size, int* v, int v_min, int v_max, const char* display_format = "%.0f");


    // Widgets: Color Editor/Picker (tip: the ColorEdit* functions have a little colored preview square that can be left-clicked to open a picker, and right-clicked to open an option menu.)
    // Note that a 'float v[X]' function argument is the same as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible. You can the pass the address of a first float element out of a contiguous structure, e.g. &myvector.x
    ColorEdit3 :: (label: *u8, col: *[3]float, flags: ColorEditFlags = 0) -> bool #foreign imgui "_ZN5ImGui10ColorEdit3EPKcPfi";
    ColorEdit4 :: (label: *u8, col: *[4]float, flags: ColorEditFlags = 0) -> bool #foreign imgui "_ZN5ImGui10ColorEdit4EPKcPfi";
    ColorPicker3 :: (label: *u8, col: *[3]float, flags: ColorEditFlags = 0) -> bool #foreign imgui "_ZN5ImGui12ColorPicker3EPKcPfi";
    ColorPicker4 :: (label: *u8, col: *[4]float, flags: ColorEditFlags = 0, ref_col: *float = null) -> bool #foreign imgui "_ZN5ImGui12ColorPicker4EPKcPfiPKf";
    ColorButton :: (desc_id: *u8, col: *ImVec4, flags: ColorEditFlags = 0, size: ImVec2/* = ImVec2(0,0)*/) -> bool #foreign imgui "_ZN5ImGui11ColorButtonEPKcRK6ImVec4i6ImVec2";  // display a colored square/button, hover for details, return true when pressed.
    SetColorEditOptions :: (flags: ColorEditFlags) #foreign imgui "_ZN5ImGui19SetColorEditOptionsEi";                         // initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.

    // Widgets: Trees
    TreeNode :: (label: *u8) -> bool #foreign imgui "_ZN5ImGui8TreeNodeEPKc";                                            // if returning 'true' the node is open and the tree id is pushed into the id stack. user is responsible for calling TreePop().
    // IMGUI_API bool          TreeNode(const char* str_id, const char* fmt, ...) IM_FMTARGS(2);       // read the FAQ about why and how to use ID. to align arbitrary text at the same level as a TreeNode() you can use Bullet().
    // IMGUI_API bool          TreeNode(const void* ptr_id, const char* fmt, ...) IM_FMTARGS(2);       // "
    // IMGUI_API bool          TreeNodeV(const char* str_id, const char* fmt, va_list args) IM_FMTLIST(2);
    // IMGUI_API bool          TreeNodeV(const void* ptr_id, const char* fmt, va_list args) IM_FMTLIST(2);
    // IMGUI_API bool          TreeNodeEx(const char* label, ImGuiTreeNodeFlags flags = 0);
    // IMGUI_API bool          TreeNodeEx(const char* str_id, ImGuiTreeNodeFlags flags, const char* fmt, ...) IM_FMTARGS(3);
    // IMGUI_API bool          TreeNodeEx(const void* ptr_id, ImGuiTreeNodeFlags flags, const char* fmt, ...) IM_FMTARGS(3);
    // IMGUI_API bool          TreeNodeExV(const char* str_id, ImGuiTreeNodeFlags flags, const char* fmt, va_list args) IM_FMTLIST(3);
    // IMGUI_API bool          TreeNodeExV(const void* ptr_id, ImGuiTreeNodeFlags flags, const char* fmt, va_list args) IM_FMTLIST(3);
    // IMGUI_API void          TreePush(const char* str_id);                                           // ~ Indent()+PushId(). Already called by TreeNode() when returning true, but you can call Push/Pop yourself for layout purpose
    // IMGUI_API void          TreePush(const void* ptr_id = NULL);                                    // "
    TreePop :: () #foreign imgui "_ZN5ImGui7TreePopEv";                                                              // ~ Unindent()+PopId()
    // IMGUI_API void          TreeAdvanceToLabelPos();                                                // advance cursor x position by GetTreeNodeToLabelSpacing()
    // IMGUI_API float         GetTreeNodeToLabelSpacing();                                            // horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
    // IMGUI_API void          SetNextTreeNodeOpen(bool is_open, ImGuiCond cond = 0);                  // set next TreeNode/CollapsingHeader open state.
    // IMGUI_API bool          CollapsingHeader(const char* label, ImGuiTreeNodeFlags flags = 0);      // if returning 'true' the header is open. doesn't indent nor push on ID stack. user doesn't have to call TreePop().
    // IMGUI_API bool          CollapsingHeader(const char* label, bool* p_open, ImGuiTreeNodeFlags flags = 0); // when 'p_open' isn't NULL, display an additional small close button on upper right of the header

    TreeNode :: (fmt: string, args: ..Any) -> bool {
        txt := tprintz(fmt, ..args);    // Note that tprintz appends a \0 at the end!
        return TreeNode(txt.data);
    }


    // Widgets: Selectable / Lists
    Selectable :: (label: *u8, selected:=false, flags:SelectableFlags=0, size:*ImVec2/*=ImVec2(0,0)*/) -> bool #foreign imgui "_ZN5ImGui10SelectableEPKcbiRK6ImVec2";  // size.x==0.0: use remaining width, size.x>0.0: specify width. size.y==0.0: use label height, size.y>0.0: specify height
    Selectable :: (label: *u8, p_selected:*bool, flags:SelectableFlags=0, size:*ImVec2/*=ImVec2(0,0)*/) -> bool #foreign imgui "_ZN5ImGui10SelectableEPKcPbiRK6ImVec2";
    ListBox :: (label: *u8, current_item: *s32, items:**u8, items_count:s32, height_in_items:s32=-1) -> bool #foreign imgui "_ZN5ImGui7ListBoxEPKcPiPKS1_ii";
    //ListBox :: (label: *u8, current_item: *s32, bool (*items_getter)(void* data, s32 idx, const char** out_text), data:*void, items_count:s32, height_in_items:s32=-1) -> bool #foreign imgui "?ListBox@ImGui@@YA_NPEBDPEAHP6A_NPEAXHPEAPEBD@Z2HH@Z";
    ListBoxHeader :: (label: *u8, size:*ImVec2/*=ImVec2(0,0)*/) -> bool #foreign imgui "_ZN5ImGui13ListBoxHeaderEPKcRK6ImVec2";     // use if you want to reimplement ListBox() will custom data or s32eractions. make sure to call ListBoxFooter() afterwards.
    ListBoxHeader :: (label: *u8, items_count: s32, height_in_items:s32=-1) -> bool #foreign imgui "_ZN5ImGui13ListBoxHeaderEPKcii"; // "
    ListBoxFooter :: () #foreign imgui "_ZN5ImGui13ListBoxFooterEv";                                                        // terminate the scrolling region

    // Widgets: Value() Helpers. Output single value in "name: value" format (tip: freely declare more in your code to handle your types. you can add functions to the ImGui namespace)
    // IMGUI_API void          Value(const char* prefix, bool b);
    // IMGUI_API void          Value(const char* prefix, int v);
    // IMGUI_API void          Value(const char* prefix, unsigned int v);
    // IMGUI_API void          Value(const char* prefix, float v, const char* float_format = NULL);

    // Tooltips
    // IMGUI_API void          SetTooltip(const char* fmt, ...) IM_FMTARGS(1);                     // set text tooltip under mouse-cursor, typically use with ImGui::IsItemHovered(). overidde any previous call to SetTooltip().
    // IMGUI_API void          SetTooltipV(const char* fmt, va_list args) IM_FMTLIST(1);
    BeginTooltip :: () #foreign imgui "_ZN5ImGui12BeginTooltipEv";                                 // begin/append a tooltip window. to create full-featured tooltip (with any kind of contents).
    EndTooltip :: () #foreign imgui "_ZN5ImGui10EndTooltipEv";

    // Menus
    BeginMainMenuBar :: () -> bool #foreign imgui "_ZN5ImGui16BeginMainMenuBarEv";                                                        // create and append to a full screen menu-bar. only call EndMainMenuBar() if this returns true!
    EndMainMenuBar :: () #foreign imgui "_ZN5ImGui14EndMainMenuBarEv";
    BeginMenuBar :: () -> bool #foreign imgui "_ZN5ImGui12BeginMenuBarEv";                                                                // append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window). only call EndMenuBar() if this returns true!
    EndMenuBar :: () #foreign imgui "_ZN5ImGui10EndMenuBarEv";
    BeginMenu :: (label: *u8, enabled:=true) -> bool #foreign imgui "_ZN5ImGui9BeginMenuEPKcb";                                       // create a sub-menu entry. only call EndMenu() if this returns true!
    EndMenu :: () #foreign imgui "_ZN5ImGui7EndMenuEv";
    MenuItem :: (label: *u8, shortcut:*u8=null, selected:=false, enabled:=true) -> bool #foreign imgui "_ZN5ImGui8MenuItemEPKcS1_bb";   // return true when activated. shortcuts are displayed for convenience but not processed by ImGui at the moment
    MenuItem :: (label: *u8, shortcut:*u8, p_selected:*bool, enabled:=true) -> bool #foreign imgui "_ZN5ImGui8MenuItemEPKcS1_Pbb";   // return true when activated + toggle (*p_selected) if p_selected != NULL

    // Popups
    // IMGUI_API void          OpenPopup(const char* str_id);                                      // call to mark popup as open (don't call every frame!). popups are closed when user click outside, or if CloseCurrentPopup() is called within a BeginPopup()/EndPopup() block. By default, Selectable()/MenuItem() are calling CloseCurrentPopup(). Popup identifiers are relative to the current ID-stack (so OpenPopup and BeginPopup needs to be at the same level).
    // IMGUI_API bool          OpenPopupOnItemClick(const char* str_id = NULL, int mouse_button = 1);                                  // helper to open popup when clicked on last item. return true when just opened.
    // IMGUI_API bool          BeginPopup(const char* str_id);                                     // return true if the popup is open, and you can start outputting to it. only call EndPopup() if BeginPopup() returned true!
    // IMGUI_API bool          BeginPopupModal(const char* name, bool* p_open = NULL, ImGuiWindowFlags extra_flags = 0);               // modal dialog (block interactions behind the modal window, can't close the modal window by clicking outside)
    BeginPopupContextItem :: (str_id : *u8 = null, mouse_button : s32 = 1) -> bool #foreign imgui "_ZN5ImGui21BeginPopupContextItemEPKci"; // helper to open and begin popup when clicked on last item. if you can pass a NULL str_id only if the previous item had an id. If you want to use that on a non-interactive item such as Text() you need to pass in an explicit ID here. read comments in .cpp!
    BeginPopupContextWindow :: (str_id : *u8 = null, mouse_button : s32 = 1, also_over_items : bool = true) -> bool #foreign imgui "_ZN5ImGui23BeginPopupContextWindowEPKcib"; // helper to open and begin popup when clicked on current window.
    BeginPopupContextVoid :: (str_id : *u8 = null, mouse_button : s32 = 1) -> bool #foreign imgui "_ZN5ImGui21BeginPopupContextVoidEPKci";                                     // helper to open and begin popup when clicked in void (where there are no imgui windows).
    EndPopup :: () #foreign imgui "_ZN5ImGui8EndPopupEv";
    IsPopupOpen :: (str_id : *u8) -> bool #foreign imgui "_ZN5ImGui11IsPopupOpenEj";               // return true if the popup is open
    // IMGUI_API void          CloseCurrentPopup();                                                // close the popup we have begin-ed into. clicking on a MenuItem or Selectable automatically close the current popup.

    // Logging/Capture: all text output from interface is captured to tty/file/clipboard. By default, tree nodes are automatically opened during logging.
    // IMGUI_API void          LogToTTY(int max_depth = -1);                                       // start logging to tty
    // IMGUI_API void          LogToFile(int max_depth = -1, const char* filename = NULL);         // start logging to file
    // IMGUI_API void          LogToClipboard(int max_depth = -1);                                 // start logging to OS clipboard
    // IMGUI_API void          LogFinish();                                                        // stop logging (close file, etc.)
    // IMGUI_API void          LogButtons();                                                       // helper to display buttons for logging to tty/file/clipboard
    // IMGUI_API void          LogText(const char* fmt, ...) IM_FMTARGS(1);                        // pass text data straight to log (without being displayed)

    // Drag and Drop
    // [BETA API] Missing Demo code. API may evolve.
    // IMGUI_API bool          BeginDragDropSource(ImGuiDragDropFlags flags = 0, int mouse_button = 0);                // call when the current item is active. If this return true, you can call SetDragDropPayload() + EndDragDropSource()
    // IMGUI_API bool          SetDragDropPayload(const char* type, const void* data, size_t size, ImGuiCond cond = 0);// type is a user defined string of maximum 8 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui.
    // IMGUI_API void          EndDragDropSource();
    // IMGUI_API bool          BeginDragDropTarget();                                                                  // call after submitting an item that may receive an item. If this returns true, you can call AcceptDragDropPayload() + EndDragDropTarget()
    // IMGUI_API const ImGuiPayload* AcceptDragDropPayload(const char* type, ImGuiDragDropFlags flags = 0);            // accept contents of a given type. If ImGuiDragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.
    // IMGUI_API void          EndDragDropTarget();

    // Clipping
    // IMGUI_API void          PushClipRect(const ImVec2& clip_rect_min, const ImVec2& clip_rect_max, bool intersect_with_current_clip_rect);
    // IMGUI_API void          PopClipRect();

    // Styles
    StyleColorsClassic :: (dst:*Style=null) #foreign imgui "_ZN5ImGui18StyleColorsClassicEP10ImGuiStyle";
    StyleColorsDark :: (dst:*Style=null) #foreign imgui "_ZN5ImGui15StyleColorsDarkEP10ImGuiStyle";
    StyleColorsLight :: (dst:*Style=null) #foreign imgui "_ZN5ImGui16StyleColorsLightEP10ImGuiStyle";

    // Focus
    // (FIXME: Those functions will be reworked after we merge the navigation branch + have a pass at focusing/tabbing features.)
    // (Prefer using "SetItemDefaultFocus()" over "if (IsWindowAppearing()) SetScrollHere()" when applicable, to make your code more forward compatible when navigation branch is merged)
    SetItemDefaultFocus :: () #foreign imgui "_ZN5ImGui19SetItemDefaultFocusEv";                                              // make last item the default focused item of a window (WIP navigation branch only). Pleaase use instead of SetScrollHere().
    SetKeyboardFocusHere :: (offset : s32 = 0) #foreign imgui "_ZN5ImGui20SetKeyboardFocusHereEi"; // focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.

    // Utilities
    IsItemHovered :: (flags:ImGuiHoveredFlags=0) -> bool #foreign imgui "_ZN5ImGui13IsItemHoveredEi"; // is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGuiHoveredFlags for more options.
    // IMGUI_API bool          IsItemActive();                                                     // is the last item active? (e.g. button being held, text field being edited- items that don't interact will always return false)
    // IMGUI_API bool          IsItemClicked(int mouse_button = 0);                                // is the last item clicked? (e.g. button/node just clicked on)
    // IMGUI_API bool          IsItemVisible();                                                    // is the last item visible? (aka not out of sight due to clipping/scrolling.)
    // IMGUI_API bool          IsAnyItemHovered();
    IsAnyItemActive :: () -> bool #foreign imgui "_ZN5ImGui15IsAnyItemActiveEv";
    // IMGUI_API ImVec2        GetItemRectMin();                                                   // get bounding rectangle of last item, in screen space
    // IMGUI_API ImVec2        GetItemRectMax();                                                   // "
    // IMGUI_API ImVec2        GetItemRectSize();                                                  // get size of last item, in screen space
    // IMGUI_API void          SetItemAllowOverlap();                                              // allow last item to be overlapped by a subsequent item. sometimes useful with invisible buttons, selectables, etc. to catch unused area.
    IsWindowFocused :: (flags:ImGuiFocusedFlags=0) -> bool #foreign imgui "_ZN5ImGui15IsWindowFocusedEi"; // is current window focused? or its root/child, depending on flags. see flags for options.
    IsWindowHovered :: (flags:ImGuiHoveredFlags=0) -> bool #foreign imgui "_ZN5ImGui15IsWindowHoveredEi"; // is current window hovered (and typically: not blocked by a popup/modal)? see flags for options.
    // IMGUI_API bool          IsAnyWindowFocused();
    // IMGUI_API bool          IsAnyWindowHovered();                                               // is mouse hovering any visible window
    // IMGUI_API bool          IsRectVisible(const ImVec2& size);                                  // test if rectangle (of given size, starting from cursor position) is visible / not clipped.
    // IMGUI_API bool          IsRectVisible(const ImVec2& rect_min, const ImVec2& rect_max);      // test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
    // IMGUI_API float         GetTime();
    // IMGUI_API int           GetFrameCount();
    // IMGUI_API ImDrawList*   GetOverlayDrawList();                                               // this draw list will be the last rendered one, useful to quickly draw overlays shapes/text
    // IMGUI_API ImDrawListSharedData* GetDrawListSharedData();
    // IMGUI_API const char*   GetStyleColorName(ImGuiCol idx);
    // IMGUI_API ImVec2        CalcItemRectClosestPoint(const ImVec2& pos, bool on_edge = false, float outward = +0.0f);   // utility to find the closest point the last item bounding rectangle edge. useful to visually link items
    // IMGUI_API ImVec2        CalcTextSize(const char* text, const char* text_end = NULL, bool hide_text_after_double_hash = false, float wrap_width = -1.0f);
    // IMGUI_API void          CalcListClipping(int items_count, float items_height, int* out_items_display_start, int* out_items_display_end);    // calculate coarse clipping for large list of evenly sized items. Prefer using the ImGuiListClipper higher-level helper if you can.

    // IMGUI_API bool          BeginChildFrame(ImGuiID id, const ImVec2& size, ImGuiWindowFlags extra_flags = 0);    // helper to create a child window / scrolling region that looks like a normal widget frame
    // IMGUI_API void          EndChildFrame();

    // IMGUI_API ImVec4        ColorConvertU32ToFloat4(ImU32 in);
    // IMGUI_API ImU32         ColorConvertFloat4ToU32(const ImVec4& in);
    // IMGUI_API void          ColorConvertRGBtoHSV(float r, float g, float b, float& out_h, float& out_s, float& out_v);
    // IMGUI_API void          ColorConvertHSVtoRGB(float h, float s, float v, float& out_r, float& out_g, float& out_b);

    // Inputs
    // IMGUI_API int           GetKeyIndex(ImGuiKey imgui_key);                                    // map ImGuiKey_* values into user's key index. == io.KeyMap[key]
    // IMGUI_API bool          IsKeyDown(int user_key_index);                                      // is key being held. == io.KeysDown[user_key_index]. note that imgui doesn't know the semantic of each entry of io.KeyDown[]. Use your own indices/enums according to how your backend/engine stored them into KeyDown[]!
    // IMGUI_API bool          IsKeyPressed(int user_key_index, bool repeat = true);               // was key pressed (went from !Down to Down). if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRate
    // IMGUI_API bool          IsKeyReleased(int user_key_index);                                  // was key released (went from Down to !Down)..
    // IMGUI_API int           GetKeyPressedAmount(int key_index, float repeat_delay, float rate); // uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
    // IMGUI_API bool          IsMouseDown(int button);                                            // is mouse button held
    IsMouseClicked       :: (button : s32, repeat : bool = false) -> bool #foreign imgui "_ZN5ImGui14IsMouseClickedEib"; // did mouse button clicked (went from !Down to Down)
    IsMouseDoubleClicked :: (button : s32) -> bool #foreign imgui "_ZN5ImGui20IsMouseDoubleClickedEi";                   // did mouse button double-clicked. a double-click returns false in IsMouseClicked(). uses io.MouseDoubleClickTime.
    IsMouseReleased      :: (button : s32) -> bool #foreign imgui "_ZN5ImGui15IsMouseReleasedEi";                        // did mouse button released (went from Down to !Down)
    IsMouseDragging      :: (button : s32 = 0, lock_threshold : float = -1.) -> bool #foreign imgui "_ZN5ImGui15IsMouseDraggingEif"; // is mouse dragging. if lock_threshold < -1.0f uses io.MouseDraggingThreshold
    // IMGUI_API bool          IsMouseHoveringRect(const ImVec2& r_min, const ImVec2& r_max, bool clip = true);  // is mouse hovering given bounding rect (in screen space). clipped by current clipping settings. disregarding of consideration of focus/window ordering/blocked by a popup.
    // IMGUI_API bool          IsMousePosValid(const ImVec2* mouse_pos = NULL);                    //
    // IMGUI_API ImVec2        GetMousePos();                                                      // shortcut to ImGui::GetIO().MousePos provided by user, to be consistent with other calls
    // IMGUI_API ImVec2        GetMousePosOnOpeningCurrentPopup();                                 // retrieve backup of mouse positioning at the time of opening popup we have BeginPopup() into
    GetMouseDragDelta :: (button : s32 = 0, lock_threshold : float = -1.) -> Vector2 #cpp_return_type_is_non_pod #foreign imgui "_ZN5ImGui17GetMouseDragDeltaEif"; // dragging amount since clicking. if lock_threshold < -1.0f uses io.MouseDraggingThreshold
    ResetMouseDragDelta ::  (button : s32 = 0) #foreign imgui "_ZN5ImGui19ResetMouseDragDeltaEi";
    GetMouseCursor :: () -> MouseCursor #foreign imgui "_ZN5ImGui14GetMouseCursorEv";              // get desired cursor type, reset in ImGui::NewFrame(), this is updated during the frame. valid before Render(). If you use software rendering by setting io.MouseDrawCursor ImGui will render those for you
    // IMGUI_API void          SetMouseCursor(ImGuiMouseCursor type);                              // set desired cursor type
    // IMGUI_API void          CaptureKeyboardFromApp(bool capture = true);                        // manually override io.WantCaptureKeyboard flag next frame (said flag is entirely left for your application handle). e.g. force capture keyboard when your widget is being hovered.
    // IMGUI_API void          CaptureMouseFromApp(bool capture = true);                           // manually override io.WantCaptureMouse flag next frame (said flag is entirely left for your application handle).

    // Helpers functions to access functions pointers in ImGui::GetIO()
    // IMGUI_API void*         MemAlloc(size_t sz);
    // IMGUI_API void          MemFree(void* ptr);
    // IMGUI_API const char*   GetClipboardText();
    // IMGUI_API void          SetClipboardText(const char* text);

    // Internal context access - if you want to use multiple context, share context between modules (e.g. DLL). There is a default context created and active by default.
    // All contexts share a same ImFontAtlas by default. If you want different font atlas, you can new() them and overwrite the GetIO().Fonts variable of an ImGui context.
    GetVersion :: () -> *u8 #foreign imgui "_ZN5ImGui10GetVersionEv";
    CreateContext :: (malloc_fn: (u64) -> *void = null, free_fn: (*void) -> () = null) -> *Context #foreign imgui "_ZN5ImGui13CreateContextEPFPvmEPFvS0_E";
    // IMGUI_API void          DestroyContext(ImGuiContext* ctx);
    // IMGUI_API ImGuiContext* GetCurrentContext();
    // IMGUI_API void          SetCurrentContext(ImGuiContext* ctx);



    // Flags for ImGui.Begin()
    WindowFlags :: enum_flags u32 {
        NoTitleBar                  :: 1 << 0;   // Disable title-bar
        NoResize                    :: 1 << 1;   // Disable user resizing with the lower-right grip
        NoMove                      :: 1 << 2;   // Disable user moving the window
        NoScrollbar                 :: 1 << 3;   // Disable scrollbars (window can still scroll with mouse or programatically)
        NoScrollWithMouse           :: 1 << 4;   // Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
        NoCollapse                  :: 1 << 5;   // Disable user collapsing window by double-clicking on it
        AlwaysAutoResize            :: 1 << 6;   // Resize every window to its content every frame
        //ShowBorders               :: 1 << 7;   // Show borders around windows and items (OBSOLETE! Use e.g. style.FrameBorderSize=1.0f to enable borders).
        NoSavedSettings             :: 1 << 8;   // Never load/save settings in .ini file
        NoInputs                    :: 1 << 9;   // Disable catching mouse or keyboard inputs, hovering test with pass through.
        MenuBar                     :: 1 << 10;  // Has a menu-bar
        HorizontalScrollbar         :: 1 << 11;  // Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
        NoFocusOnAppearing          :: 1 << 12;  // Disable taking focus when transitioning from hidden to visible state
        NoBringToFrontOnFocus       :: 1 << 13;  // Disable bringing window to front when taking focus (e.g. clicking on it or programatically giving it focus)
        AlwaysVerticalScrollbar     :: 1 << 14;  // Always show vertical scrollbar (even if ContentSize.y < Size.y)
        AlwaysHorizontalScrollbar   :: 1 << 15;  // Always show horizontal scrollbar (even if ContentSize.x < Size.x)
        AlwaysUseWindowPadding      :: 1 << 16;  // Ensure child windows without border uses style.WindowPadding (ignored by default for non-bordered child windows, because more convenient)
        ResizeFromAnySide           :: 1 << 17;  // (WIP) Enable resize from any corners and borders. Your back-end needs to honor the different values of io.MouseCursor set by imgui.
    }

    // Flags for ImGui.InputText()
    InputTextFlags :: enum_flags u32 {
        CharsDecimal        :: 1 << 0;   // Allow 0123456789.+-* /
        CharsHexadecimal    :: 1 << 1;   // Allow 0123456789ABCDEFabcdef
        CharsUppercase      :: 1 << 2;   // Turn a..z into A..Z
        CharsNoBlank        :: 1 << 3;   // Filter out spaces, tabs
        AutoSelectAll       :: 1 << 4;   // Select entire text when first taking mouse focus
        EnterReturnsTrue    :: 1 << 5;   // Return 'true' when Enter is pressed (as opposed to when the value was modified)
        CallbackCompletion  :: 1 << 6;   // Call user function on pressing TAB (for completion handling)
        CallbackHistory     :: 1 << 7;   // Call user function on pressing Up/Down arrows (for history handling)
        CallbackAlways      :: 1 << 8;   // Call user function every time. User code may query cursor position, modify text buffer.
        CallbackCharFilter  :: 1 << 9;   // Call user function to filter character. Modify data->EventChar to replace/filter input, or return 1 to discard character.
        AllowTabInput       :: 1 << 10;  // Pressing TAB input a '\t' character into the text field
        CtrlEnterForNewLine :: 1 << 11;  // In multi-line mode, unfocus with Enter, add new line with Ctrl+Enter (default is opposite: unfocus with Ctrl+Enter, add line with Enter).
        NoHorizontalScroll  :: 1 << 12;  // Disable following the cursor horizontally
        AlwaysInsertMode    :: 1 << 13;  // Insert mode
        ReadOnly            :: 1 << 14;  // Read-only mode
        Password            :: 1 << 15;  // Password mode, display all characters as '*'
        NoUndoRedo          :: 1 << 16;  // Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
    }

    // Flags for ImGui.TreeNodeEx(), ImGui.CollapsingHeader*()
    TreeNodeFlags :: enum_flags u32 {
        Selected             :: 1 << 0;   // Draw as selected
        Framed               :: 1 << 1;   // Full colored frame (e.g. for CollapsingHeader)
        AllowItemOverlap     :: 1 << 2;   // Hit testing to allow subsequent widgets to overlap this one
        NoTreePushOnOpen     :: 1 << 3;   // Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
        NoAutoOpenOnLog      :: 1 << 4;   // Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
        DefaultOpen          :: 1 << 5;   // Default node to be open
        OpenOnDoubleClick    :: 1 << 6;   // Need double-click to open node
        OpenOnArrow          :: 1 << 7;   // Only open when clicking on the arrow part. If OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
        Leaf                 :: 1 << 8;   // No collapsing, no arrow (use as a convenience for leaf nodes). 
        Bullet               :: 1 << 9;   // Display a bullet instead of arrow
        FramePadding         :: 1 << 10;  // Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding().
        CollapsingHeader     :: Framed | NoAutoOpenOnLog;
    }

    // Flags for ImGui.Selectable()
    SelectableFlags :: enum_flags u32 {
        DontClosePopups    :: 1 << 0;   // Clicking this don't close parent popup window
        SpanAllColumns     :: 1 << 1;   // Selectable frame can span all columns (text will still fit in current column)
        AllowDoubleClick   :: 1 << 2;   // Generate press events on double clicks too
    }

    // Flags for ImGui.BeginCombo()
    ComboFlags :: enum_flags u32 {
        PopupAlignLeft          :: 1 << 0;   // Align the popup toward the left by default
        HeightSmall             :: 1 << 1;   // Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
        HeightRegular           :: 1 << 2;   // Max ~8 items visible (default)
        HeightLarge             :: 1 << 3;   // Max ~20 items visible
        HeightLargest           :: 1 << 4;   // As many fitting items as possible
        HeightMask              :: HeightSmall | HeightRegular | HeightLarge | HeightLargest;
    }

    // Flags for ImGui.IsWindowFocused()
    FocusedFlags :: enum_flags u32 {
        ChildWindows            :: 1 << 0;   // IsWindowFocused(): Return true if any children of the window is focused
        RootWindow              :: 1 << 1;   // IsWindowFocused(): Test from root window (top most parent of the current hierarchy)
        RootAndChildWindows     :: RootWindow | ChildWindows;
    }

    // Flags for ImGui.IsItemHovered(), ImGui.IsWindowHovered()
    HoveredFlags :: enum_flags u32 {
        Default                         :: 0;        // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
        ChildWindows                    :: 1 << 0;   // IsWindowHovered() only: Return true if any children of the window is hovered
        RootWindow                      :: 1 << 1;   // IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
        AllowWhenBlockedByPopup         :: 1 << 2;   // Return true even if a popup window is normally blocking access to this item/window
        //AllowWhenBlockedByModal       :: 1 << 3;   // Return true even if a modal popup window is normally blocking access to this item/window. FIXME-TODO: Unavailable yet.
        AllowWhenBlockedByActiveItem    :: 1 << 4;   // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
        AllowWhenOverlapped             :: 1 << 5;   // Return true even if the position is overlapped by another window
        RectOnly                        :: AllowWhenBlockedByPopup | AllowWhenBlockedByActiveItem | AllowWhenOverlapped;
        RootAndChildWindows             :: RootWindow | ChildWindows;
    }

    // Flags for ImGui.BeginDragDropSource(), ImGui.AcceptDragDropPayload()
    DragDropFlags :: enum_flags u32 {
        // BeginDragDropSource() flags
        SourceNoPreviewTooltip       :: 1 << 0;       // By default, a successful call to BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disable this behavior.
        SourceNoDisableHover         :: 1 << 1;       // By default, when dragging we clear data so that IsItemHovered() will return true, to avoid subsequent user code submitting tooltips. This flag disable this behavior so you can still call IsItemHovered() on the source item.
        SourceNoHoldToOpenOthers     :: 1 << 2;       // Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
        SourceAllowNullID            :: 1 << 3;       // Allow items such as Text(), Image() that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
        SourceExtern                 :: 1 << 4;       // External source (from outside of imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
        // AcceptDragDropPayload() flags
        AcceptBeforeDelivery         :: 1 << 10;      // AcceptDragDropPayload() will returns true even before the mouse button is released. You can then call IsDelivery() to test if the payload needs to be delivered.
        AcceptNoDrawDefaultRect      :: 1 << 11;      // Do not draw the default highlight rectangle when hovering over target.
        AcceptPeekOnly               :: AcceptBeforeDelivery | AcceptNoDrawDefaultRect;  // For peeking ahead and inspecting the payload before delivery.
    }

    // User fill IO.KeyMap[] array with indices into the IO.KeysDown[512] array
    Key :: enum s32 {
        Tab;       // for tabbing through fields
        LeftArrow; // for text edit
        RightArrow;// for text edit
        UpArrow;   // for text edit
        DownArrow; // for text edit
        PageUp;
        PageDown;
        Home;      // for text edit
        End;       // for text edit
        Delete;    // for text edit
        Backspace; // for text edit
        Enter;     // for text edit
        Escape;    // for text edit
        A;         // for text edit CTRL+A: select all
        C;         // for text edit CTRL+C: copy
        V;         // for text edit CTRL+V: paste
        X;         // for text edit CTRL+X: cut
        Y;         // for text edit CTRL+Y: redo
        Z;         // for text edit CTRL+Z: undo
        count;
    }

    // Enumeration for PushStyleColor() / PopStyleColor()
    Col :: enum s32 {
        Text;
        TextDisabled;
        WindowBg;              // Background of normal windows
        ChildBg;               // Background of child windows
        PopupBg;               // Background of popups, menus, tooltips windows
        Border;
        BorderShadow;
        FrameBg;               // Background of checkbox, radio button, plot, slider, text input
        FrameBgHovered;
        FrameBgActive;
        TitleBg;
        TitleBgActive;
        TitleBgCollapsed;
        MenuBarBg;
        ScrollbarBg;
        ScrollbarGrab;
        ScrollbarGrabHovered;
        ScrollbarGrabActive;
        CheckMark;
        SliderGrab;
        SliderGrabActive;
        Button;
        ButtonHovered;
        ButtonActive;
        Header;
        HeaderHovered;
        HeaderActive;
        Separator;
        SeparatorHovered;
        SeparatorActive;
        ResizeGrip;
        ResizeGripHovered;
        ResizeGripActive;
        CloseButton;
        CloseButtonHovered;
        CloseButtonActive;
        PlotLines;
        PlotLinesHovered;
        PlotHistogram;
        PlotHistogramHovered;
        TextSelectedBg;
        ModalWindowDarkening;  // darken entire screen when a modal window is active
        DragDropTarget;
        count; // @@ Use enum api to get this?
    }

    // Enumeration for PushStyleVar() / PopStyleVar() to temporarily modify the ImGuiStyle structure.
    // NB: the enum only refers to fields of ImGuiStyle which makes sense to be pushed/popped inside UI code. During initialization, feel free to just poke into ImGuiStyle directly.
    // NB: if changing this enum, you need to update the associated internal table GStyleVarInfo[] accordingly. This is where we link enum values to members offset/type.
    StyleVar :: enum s32 {
        // Enum name ......................// Member in ImGuiStyle structure (see ImGuiStyle for descriptions)
        Alpha;               // float     Alpha
        WindowPadding;       // ImVec2    WindowPadding
        WindowRounding;      // float     WindowRounding
        WindowBorderSize;    // float     WindowBorderSize
        WindowMinSize;       // ImVec2    WindowMinSize
        ChildRounding;       // float     ChildRounding
        ChildBorderSize;     // float     ChildBorderSize
        PopupRounding;       // float     PopupRounding
        PopupBorderSize;     // float     PopupBorderSize
        FramePadding;        // ImVec2    FramePadding
        FrameRounding;       // float     FrameRounding
        FrameBorderSize;     // float     FrameBorderSize
        ItemSpacing;         // ImVec2    ItemSpacing
        ItemInnerSpacing;    // ImVec2    ItemInnerSpacing
        IndentSpacing;       // float     IndentSpacing
        GrabMinSize;         // float     GrabMinSize
        ButtonTextAlign;     // ImVec2    ButtonTextAlign
    }

    // Enumeration for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
    ColorEditFlags :: enum_flags u32 {
        NoAlpha         :: 1 << 1;   //              // ColorEdit, ColorPicker, ColorButton: ignore Alpha component (read 3 components from the input pointer).
        NoPicker        :: 1 << 2;   //              // ColorEdit: disable picker when clicking on colored square.
        NoOptions       :: 1 << 3;   //              // ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
        NoSmallPreview  :: 1 << 4;   //              // ColorEdit, ColorPicker: disable colored square preview next to the inputs. (e.g. to show only the inputs)
        NoInputs        :: 1 << 5;   //              // ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview colored square).
        NoTooltip       :: 1 << 6;   //              // ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
        NoLabel         :: 1 << 7;   //              // ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
        NoSidePreview   :: 1 << 8;   //              // ColorPicker: disable bigger color preview on right side of the picker, use small colored square preview instead.
        // User Options (right-click on widget to change some of them). You can set application defaults using SetColorEditOptions(). The idea is that you probably don't want to override them in most of your calls, let the user choose and/or call SetColorEditOptions() during startup.
        AlphaBar        :: 1 << 9;   //              // ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
        AlphaPreview    :: 1 << 10;  //              // ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
        AlphaPreviewHalf:: 1 << 11;  //              // ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
        HDR             :: 1 << 12;  //              // (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use Float flag as well).
        RGB             :: 1 << 13;  // [Inputs]     // ColorEdit: choose one among RGB/HSV/HEX. ColorPicker: choose any combination using RGB/HSV/HEX.
        HSV             :: 1 << 14;  // [Inputs]     // "
        HEX             :: 1 << 15;  // [Inputs]     // "
        Uint8           :: 1 << 16;  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255. 
        Float           :: 1 << 17;  // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
        PickerHueBar    :: 1 << 18;  // [PickerMode] // ColorPicker: bar for Hue, rectangle for Sat/Value.
        PickerHueWheel  :: 1 << 19;  // [PickerMode] // ColorPicker: wheel for Hue, triangle for Sat/Value.
    }

    // Enumeration for GetMouseCursor()
    MouseCursor :: enum s32 {
        None :: -1;
        Arrow :: 0;
        TextInput;         // When hovering over InputText, etc.
        Move;              // Unused
        ResizeNS;          // When hovering over an horizontal border
        ResizeEW;          // When hovering over a vertical border or a column
        ResizeNESW;        // When hovering over the bottom-left corner of a window
        ResizeNWSE;        // When hovering over the bottom-right corner of a window
    }

    // Condition for ImGui::SetWindow***(), SetNextWindow***(), SetNextTreeNode***() functions
    // All those functions treat 0 as a shortcut to ImGuiCond_Always. From the point of view of the user use this as an enum (don't combine multiple values into flags).
    Cond :: enum_flags {
        Always        :: 1 << 0;   // Set the variable
        Once          :: 1 << 1;   // Set the variable once per runtime session (only the first call with succeed)
        FirstUseEver  :: 1 << 2;   // Set the variable if the window has no saved data (if doesn't exist in the .ini file)
        Appearing     :: 1 << 3;   // Set the variable if the window is appearing after being hidden/inactive (or the first time)
    }


    Style :: struct {
        Alpha:                  float;          // Global alpha applies to everything in ImGui
        WindowPadding:          Vector2;        // Padding within a window
        WindowRounding:         float;          // Radius of window corners rounding. Set to 0.0f to have rectangular windows
        WindowBorderSize:       float;          // Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly)
        WindowMinSize:          Vector2;        // Minimum window size
        WindowTitleAlign:       Vector2;        // Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.
        ChildRounding:          float;          // Radius of child window corners rounding. Set to 0.0f to have rectangular windows.
        ChildBorderSize:        float;          // Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly)
        PopupRounding:          float;          // Radius of popup window corners rounding.
        PopupBorderSize:        float;          // Thickness of border around popup windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly)
        FramePadding:           Vector2;        // Padding within a framed rectangle (used by most widgets)
        FrameRounding:          float;          // Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).
        FrameBorderSize:        float;          // Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly)
        ItemSpacing:            Vector2;        // Horizontal and vertical spacing between widgets/lines
        ItemInnerSpacing:       Vector2;        // Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label)
        TouchExtraPadding:      Vector2;        // Expand reactive bounding box for touch-based system where touch position is not accurate enough. Unfortunately we don't sort widgets so priority on overlap will always be given to the first widget. So don't grow this too much!
        IndentSpacing:          float;          // Horizontal indentation when e.g. entering a tree node. Generally == (FontSize + FramePadding.x*2).
        ColumnsMinSpacing:      float;          // Minimum horizontal spacing between two columns
        ScrollbarSize:          float;          // Width of the vertical scrollbar, Height of the horizontal scrollbar
        ScrollbarRounding:      float;          // Radius of grab corners for scrollbar
        GrabMinSize:            float;          // Minimum width/height of a grab box for slider/scrollbar.
        GrabRounding:           float;          // Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
        ButtonTextAlign:        Vector2;        // Alignment of button text when button is larger than text. Defaults to (0.5f,0.5f) for horizontally+vertically centered.
        DisplayWindowPadding:   Vector2;        // Window positions are clamped to be visible within the display area by at least this amount. Only covers regular windows.
        DisplaySafeAreaPadding: Vector2;        // If you cannot see the edge of your screen (e.g. on a TV) increase the safe area padding. Covers popups/tooltips as well regular windows.
        AntiAliasedLines:       bool;           // Enable anti-aliasing on lines/borders. Disable if you are really tight on CPU/GPU.
        AntiAliasedFill:        bool;           // Enable anti-aliasing on filled shapes (rounded rectangles, circles, etc.)
        CurveTessellationTol:   float;          // Tessellation tolerance when using PathBezierCurveTo() without a specific number of segments. Decrease for highly tessellated curves (higher quality, more polygons), increase to reduce quality.
        Colors:                 [Col.count] Vector4;

        //ImGuiStyle();
        //void ScaleAllSizes(float scale_factor);
    }


    // This is where your app communicate with ImGui. Access via ImGui.GetIO().
    // Read 'Programmer guide' section in .cpp file for general usage.
    IO :: struct {
        //------------------------------------------------------------------
        // Settings (fill once)                 // Default value:
        //------------------------------------------------------------------

        DisplaySize: Vector2;               // <unset>              // Display size, in pixels. For clamping windows positions.
        DeltaTime: float;                   // = 1.0f/60.0f         // Time elapsed since last frame, in seconds.
        IniSavingRate: float;               // = 5.0f               // Maximum time between saving positions/sizes to .ini file, in seconds.
        IniFilename: *u8;                   // = "imgui.ini"        // Path to .ini file. NULL to disable .ini saving.
        LogFilename: *u8;                   // = "imgui_log.txt"    // Path to .log file (default parameter to ImGui::LogToFile when no file is specified).
        MouseDoubleClickTime: float;        // = 0.30f              // Time for a double-click, in seconds.
        MouseDoubleClickMaxDist: float;     // = 6.0f               // Distance threshold to stay in to validate a double-click, in pixels.
        MouseDragThreshold: float;          // = 6.0f               // Distance threshold before considering we are dragging
        KeyMap: [Key.count]s32;             // <unset>              // Map of indices into the KeysDown[512] entries array
        KeyRepeatDelay: float;              // = 0.250f             // When holding a key/button, time before it starts repeating, in seconds (for buttons in Repeat mode, etc.).
        KeyRepeatRate: float;               // = 0.050f             // When holding a key/button, rate at which it repeats, in seconds.
        UserData: *void;                    // = NULL               // Store your own data for retrieval by callbacks.

        Fonts: *ImFontAtlas;                // <auto>               // Load and assemble one or more fonts into a single tightly packed texture. Output to Fonts array.
        FontGlobalScale: float;             // = 1.0f               // Global scale all fonts
        FontAllowUserScaling: bool;         // = false              // Allow user scaling text of individual window with CTRL+Wheel.
        FontDefault: *ImFont;               // = NULL               // Font to use on NewFrame(). Use NULL to uses Fonts->Fonts[0].
        DisplayFramebufferScale: Vector2;   // = (1.0f,1.0f)        // For retina display or other situations where window coordinates are different from framebuffer coordinates. User storage only, presently not used by ImGui.
        DisplayVisibleMin: Vector2;         // <unset> (0.0f,0.0f)  // If you use DisplaySize as a virtual space larger than your screen, set DisplayVisibleMin/Max to the visible area.
        DisplayVisibleMax: Vector2;         // <unset> (0.0f,0.0f)  // If the values are the same, we defaults to Min=(0.0f) and Max=DisplaySize

        // Advanced/subtle behaviors
        OptMacOSXBehaviors: bool;           // = defined(__APPLE__) // OS X style: Text editing cursor movement using Alt instead of Ctrl, Shortcuts using Cmd/Super instead of Ctrl, Line/Text Start and End using Cmd+Arrows instead of Home/End, Double click selects by word instead of selecting whole text, Multi-selection in lists uses Cmd/Super instead of Ctrl
        OptCursorBlink: bool;               // = true               // Enable blinking cursor, for users who consider it annoying.

        //------------------------------------------------------------------
        // Settings (User Functions)
        //------------------------------------------------------------------

        // Rendering function, will be called in Render().
        // Alternatively you can keep this to NULL and call GetDrawData() after Render() to get the same pointer.
        // See example applications if you are unsure of how to implement this.
        RenderDrawListsFn : (data: *ImDrawData) #c_call;

        // Optional: access OS clipboard
        // (default to use native Win32 clipboard on Windows, otherwise uses a private clipboard. Override to access OS clipboard on other architectures)
        GetClipboardTextFn : (user_data: *void) -> *u8 #c_call;
        SetClipboardTextFn : (user_data: *void, text: *u8) #c_call;
        ClipboardUserData: *void;

        // Optional: override memory allocations. MemFreeFn() may be called with a NULL pointer.
        // (default to posix malloc/free)
        MemAllocFn : (sz: s64) -> *void #c_call;
        MemFreeFn : (ptr:*void) #c_call;

        // Optional: notify OS Input Method Editor of the screen position of your cursor for text input position (e.g. when using Japanese/Chinese IME in Windows)
        // (default to use native imm32 api on Windows)
        ImeSetInputScreenPosFn : (x: s32, y: s32) #c_call;
        ImeWindowHandle: *void;           // (Windows) Set this to your HWND to get automatic IME cursor positioning.

        //------------------------------------------------------------------
        // Input - Fill before calling NewFrame()
        //------------------------------------------------------------------

        MousePos: ImVec2;                 // Mouse position, in pixels. Set to ImVec2(-FLT_MAX,-FLT_MAX) if mouse is unavailable (on another screen, etc.)
        MouseDown: [5]bool;               // Mouse buttons: left, right, middle + extras. ImGui itself mostly only uses left button (BeginPopupContext** are using right button). Others buttons allows us to track if the mouse is being used by your application + available to user as a convenience via IsMouse** API.
        MouseWheel: float;                // Mouse wheel: 1 unit scrolls about 5 lines text.
        MouseDrawCursor: bool;            // Request ImGui to draw a mouse cursor for you (if you are on a platform without a mouse cursor).
        KeyCtrl: bool;                    // Keyboard modifier pressed: Control
        KeyShift: bool;                   // Keyboard modifier pressed: Shift
        KeyAlt: bool;                     // Keyboard modifier pressed: Alt
        KeySuper: bool;                   // Keyboard modifier pressed: Cmd/Super/Windows
        KeysDown: [512]bool;              // Keyboard keys that are pressed (in whatever storage order you naturally have access to keyboard data)
        InputCharacters: [16+1]ImWchar;   // List of characters input (translated by user from keypress+keyboard state). Fill using AddInputCharacter() helper.

        // Functions
        AddInputCharacter :: (this:*IO, c: ImWchar)                                   // Add new character into InputCharacters[]
            #foreign imgui "_ZN7ImGuiIO17AddInputCharacterEt";
        AddInputCharactersUTF8 :: (this:*IO, utf8_chars: *u8)                         // Add new characters into InputCharacters[] from an UTF-8 string
            #foreign imgui "_ZN7ImGuiIO22AddInputCharactersUTF8EPKc";
        ClearInputCharacters :: inline (using this: *IO) { InputCharacters[0] = 0; }       // Clear the text input buffer manually

        //------------------------------------------------------------------
        // Output - Retrieve after calling NewFrame()
        //------------------------------------------------------------------

        WantCaptureMouse: bool;         // When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application. This is set by ImGui when it wants to use your mouse (e.g. unclicked mouse is hovering a window, or a widget is active). 
        WantCaptureKeyboard: bool;      // When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application. This is set by ImGui when it wants to use your keyboard inputs.
        WantTextInput: bool;            // Mobile/console: when io.WantTextInput is true, you may display an on-screen keyboard. This is set by ImGui when it wants textual keyboard input to happen (e.g. when a InputText widget is active).
        WantMoveMouse: bool;            // [BETA-NAV] MousePos has been altered, back-end should reposition mouse on next frame. Set only when 'NavMovesMouse=true'.
        Framerate: float;               // Application framerate estimation, in frame per second. Solely for convenience. Rolling average estimation based on IO.DeltaTime over 120 frames
        MetricsAllocs: s32;             // Number of active memory allocations
        MetricsRenderVertices: s32;     // Vertices output during last call to Render()
        MetricsRenderIndices: s32;      // Indices output during last call to Render() = number of triangles * 3
        MetricsActiveWindows: s32;      // Number of visible root windows (exclude child windows)
        MouseDelta: ImVec2;             // Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.
    }

    // Shared state of InputText(), passed to callback when a ImGuiInputTextFlags_Callback* flag is used and the corresponding callback is triggered.
    TextEditCallbackData :: struct {
        EventFlag : InputTextFlags;      // One of ImGuiInputTextFlags_Callback* // Read-only
        Flags : InputTextFlags;          // What user passed to InputText()      // Read-only
        UserData : *void;                // What user passed to InputText()      // Read-only
        ReadOnly : bool;                 // Read-only mode                       // Read-only

        // CharFilter event:
        EventChar : ImWchar; // Character input                      // Read-write (replace character or set to zero)

        // Completion,History,Always events:
        // If you modify the buffer contents make sure you update 'BufTextLen' and set 'BufDirty' to true.
        EventKey : Key;       // Key pressed (Up/Down/TAB)            // Read-only
        Buf : *u8;            // Current text buffer                  // Read-write (pointed data only, can't replace the actual pointer)
        BufTextLen : s32;     // Current text length in bytes         // Read-write
        BufSize : s32;        // Maximum text length in bytes         // Read-only
        BufDirty : bool;      // Set if you modify Buf/BufTextLen!!   // Write
        CursorPos : s32;      //                                      // Read-write
        SelectionStart : s32; //                                      // Read-write (== to SelectionEnd when no selection)
        SelectionEnd : s32;   //                                      // Read-write

        // NB: Helper functions for text manipulation. Calling those function loses selection.
        DeleteChars :: (this : *TextEditCallbackData, pos : s32, bytes_count : s32) -> () #foreign imgui "_ZN25ImGuiTextEditCallbackData11DeleteCharsEii";
        InsertChars :: (this : *TextEditCallbackData, pos : s32, text : *u8, text_end : *u8 = null) -> () #foreign imgui "_ZN25ImGuiTextEditCallbackData11InsertCharsEiPKcS1_";
        HasSelection :: inline (this : *TextEditCallbackData) -> bool { return this.SelectionStart != this.SelectionEnd; }
    }

    // @@ 

    OnceUponAFrame :: struct {};
    Storage :: struct {}
    TextFilter :: struct {}
    TextBuffer :: struct {}
    SizeConstraintCallbackData :: struct {}
    ListClipper :: struct {};
    Payload :: struct {}
    Context :: struct {}
}

// All draw data to render an ImGui frame
ImDrawData :: struct {
    Valid: bool;                // Only valid after Render() is called and before the next NewFrame() is called.
    CmdLists: **ImDrawList;
    CmdListsCount: s32;
    TotalVtxCount: s32;         // For convenience, sum of all cmd_lists vtx_buffer.Size
    TotalIdxCount: s32;         // For convenience, sum of all cmd_lists idx_buffer.Size

    // Functions
    DeIndexAllBuffers :: (this:*ImDrawData) #foreign imgui "_ZN10ImDrawData17DeIndexAllBuffersEv";                    // For backward compatibility or convenience: convert all buffers from indexed to de-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
    ScaleClipRects :: (this:*ImDrawData, sc:*ImVec2) #foreign imgui "_ZN10ImDrawData14ScaleClipRectsERK6ImVec2";  // Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
}

ImFontAtlas :: struct {

    // @@ Add methods.
    Build :: (this: *ImFontAtlas) -> bool                    // Build pixels data. This is called automatically for you by the GetTexData*** functions.
        #foreign imgui "_ZN11ImFontAtlas5BuildEv";
    GetTexDataAsAlpha8 :: (this: *ImFontAtlas, out_pixels: **u8, out_width: *s32, out_height: *s32, out_bytes_per_pixel:*s32=null)  // 1 byte per-pixel
        #foreign imgui "_ZN11ImFontAtlas18GetTexDataAsAlpha8EPPhPiS2_S2_";
    GetTexDataAsRGBA32 :: (this: *ImFontAtlas, out_pixels: **u32, out_width: *s32, out_height: *s32, out_bytes_per_pixel:*s32=null)  // 4 bytes-per-pixel
        #foreign imgui "_ZN11ImFontAtlas18GetTexDataAsRGBA32EPPhPiS2_S2_";

    SetTexID :: inline (using this: *ImFontAtlas, id: ImTextureID) { TexID = id; }


    CustomRect :: struct {
        ID: u32 = 0xFFFFFFFF;           // Input    // User ID. Use <0x10000 to map into a font glyph, >=0x10000 for other/internal/custom texture data.
        Width, Height: u16;             // Input    // Desired rectangle dimension
        X, Y: u16 = 0xFFFF;             // Output   // Packed position in Atlas
        GlyphAdvanceX: float;           // Input    // For custom font glyphs only (ID<0x10000): glyph xadvance
        GlyphOffset: ImVec2;            // Input    // For custom font glyphs only (ID<0x10000): glyph display offset
        Font: *ImFont;                  // Input    // For custom font glyphs only (ID<0x10000): target font
        //bool IsPacked() const   { return X != 0xFFFF; }
    }



    TexID: ImTextureID;                 // User data to refer to the texture once it has been uploaded to user's graphic systems. It is passed back to you during rendering via the ImDrawCmd structure.
    TexDesiredWidth: s32;               // Texture width desired by user before Build(). Must be a power-of-two. If have many glyphs your graphics API have texture size restrictions you may want to increase texture width to decrease height.
    TexGlyphPadding: s32;               // Padding between glyphs within texture in pixels. Defaults to 1.

    // [Internal]
    // NB: Access texture data via GetTexData*() calls! Which will setup a default font for you.
    TexPixelsAlpha8: *u8;               // 1 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight
    TexPixelsRGBA32: *u32;              // 4 component per pixel, each component is unsigned 8-bit. Total size = TexWidth * TexHeight * 4
    TexWidth: s32;                      // Texture width calculated during Build().
    TexHeight: s32;                     // Texture height calculated during Build().
    TexUvWhitePixel: ImVec2;            // Texture coordinates to a white pixel
    Fonts: ImVector(*ImFont);           // Hold all the fonts returned by AddFont*. Fonts[0] is the default font upon calling ImGui::NewFrame(), use ImGui::PushFont()/PopFont() to change the current font.
    CustomRects: ImVector(CustomRect);  // Rectangles for packing custom texture data into the atlas.
    ConfigData: ImVector(ImFontConfig); // Internal data
    CustomRectIds: [1]s32;              // Identifiers of custom texture rectangle used by ImFontAtlas/ImDrawList

}

#scope_file 

#if OS == .MACOS {
    imgui :: #foreign_library "mac/ImGui";
} else #if OS == .LINUX {
    imgui :: #foreign_library "linux/ImGui";
}
libcpp :: #foreign_system_library "libc++"; // for linking
