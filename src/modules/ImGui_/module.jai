// Bindings for Dear ImGui.

// Module parameter:
IMGUI_ENABLE_DEMO :: true;

ImVec2      :: Vector2;
ImVec4      :: Vector4;
ImColor     :: Vector4;
ImWchar     :: u16;                 // character for keyboard input/display
ImTextureID :: *void;     // user data to identify a texture (this is whatever to you want it to be! read the FAQ about ImTextureID in imgui.cpp)
ImGuiCol    :: s32; // @Cleanup should be an enum
ImU32       :: u32;

ImVector :: struct (T: Type) {
    Size: s32;
    Capacity: s32;
    Data: *T;
}

ImDrawCallback :: #type (parent_list: *ImDrawList, cmd: *ImDrawCmd) #c_call;

ImDrawCmd :: struct {
    ElemCount: u32;                 // Number of indices (multiple of 3) to be rendered as triangles. Vertices are stored in the callee ImDrawList's vtx_buffer[] array, indices in idx_buffer[].
    ClipRect: ImVec4;               // Clipping rectangle (x1, y1, x2, y2)
    TextureId: ImTextureID;         // User-provided texture ID. Set by user in ImfontAtlas::SetTexID() for fonts or passed to Image*() functions. Ignore if never using images or multiple fonts atlas.
    UserCallback: ImDrawCallback;   // If != NULL, call the function instead of rendering the vertices. clip_rect and texture_id will be set normally.
    UserCallbackData: *void;        // The draw callback code can access this.
}

// Vertex index (override with '#define ImDrawIdx unsigned int' inside in imconfig.h)
ImDrawIdx :: u16;

ImDrawVert :: struct {
    pos: ImVec2;
    uv: ImVec2;
    col: s32;
}

// Draw channels are used by the Columns API to "split" the render list into different channels while building, so items of each column can be batched together.
// You can also use them to simulate drawing layers and submit primitives in a different order than how they will be rendered.
ImDrawChannel :: struct {
    CmdBuffer: ImVector(ImDrawCmd);
    IdxBuffer: ImVector(ImDrawIdx);
}

ImDrawCornerFlags :: enum_flags {
    TopLeft  :: 1 << 0; // 0x1
    TopRight :: 1 << 1; // 0x2
    BotLeft  :: 1 << 2; // 0x4
    BotRight :: 1 << 3; // 0x8
    Top      :: TopLeft  | TopRight; // 0x3
    Bot      :: BotLeft  | BotRight; // 0xC
    Left     :: TopLeft  | BotLeft;  // 0x5
    Right    :: TopRight | BotRight; // 0xA
    All      :: 0xF;     // In your function calls you may use ~0 (= all bits sets) instead of ImDrawCornerFlags_All, as a convenience
}

ImDrawListFlags :: enum_flags {
    AntiAliasedLines :: 1 << 0;
    AntiAliasedFill  :: 1 << 1;
}

// Draw command list
// This is the low-level list of polygons that ImGui functions are filling. At the end of the frame, all command lists are passed to your ImGuiIO::RenderDrawListFn function for rendering.
// Each ImGui window contains its own ImDrawList. You can use ImGui::GetWindowDrawList() to access the current window draw list and draw custom primitives.
// You can interleave normal ImGui:: calls and adding primitives to the current draw list.
// All positions are generally in pixel coordinates (top-left at (0,0), bottom-right at io.DisplaySize), however you are totally free to apply whatever transformation matrix to want to the data (if you apply such transformation you'll want to apply it to ClipRect as well)
// Important: Primitives are always added to the list and not culled (culling is done at higher-level by ImGui:: functions), if you use this API a lot consider coarse culling your drawn objects.
ImDrawList :: struct {

    // This is what you have to render
    CmdBuffer: ImVector(ImDrawCmd);         // Draw commands. Typically 1 command = 1 GPU draw call, unless the command is a callback.
    IdxBuffer: ImVector(ImDrawIdx);         // Index buffer. Each command consume ImDrawCmd::ElemCount of those
    VtxBuffer: ImVector(ImDrawVert);        // Vertex buffer.

    // [Internal, used while building lists]
    Flags: ImDrawListFlags;                     // Flags, you may poke into these to adjust anti-aliasing settings per-primitive.
    _Data: *ImDrawListSharedData;               // Pointer to shared draw data (you can use ImGui::GetDrawListSharedData() to get the one from current ImGui context)
    _OwnerName: *u8;                            // Pointer to owner window's name for debugging
    _VtxCurrentIdx: u32;                        // [Internal] == VtxBuffer.Size
    _VtxWritePtr: *ImDrawVert;                  // [Internal] point within VtxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    _IdxWritePtr: *ImDrawIdx;                   // [Internal] point within IdxBuffer.Data after each add command (to avoid using the ImVector<> operators too much)
    _ClipRectStack: ImVector(ImVec4);           // [Internal]
    _TextureIdStack: ImVector(ImTextureID);     // [Internal]
    _Path: ImVector(ImVec2);                    // [Internal] current path building
    _ChannelsCurrent: s32;                      // [Internal] current channel number (0)
    _ChannelsCount: s32;                        // [Internal] number of active channels (1+)
    _Channels: ImVector(ImDrawChannel);         // [Internal] draw channels for columns API (not resized down so _ChannelsCount may be smaller than _Channels.Size)

    // //ImDrawList(const ImDrawListSharedData* shared_data) { _Data = shared_data; _OwnerName = NULL; Clear(); }
    // //~ImDrawList() { ClearFreeMemory(); }
    // IMGUI_API void  PushClipRect(ImVec2 clip_rect_min, ImVec2 clip_rect_max, bool intersect_with_current_clip_rect = false);  // Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
    // IMGUI_API void  PushClipRectFullScreen();
    // IMGUI_API void  PopClipRect();
    // IMGUI_API void  PushTextureID(const ImTextureID& texture_id);
    // IMGUI_API void  PopTextureID();
    // inline ImVec2   GetClipRectMin() const { const ImVec4& cr = _ClipRectStack.back(); return ImVec2(cr.x, cr.y); }
    // inline ImVec2   GetClipRectMax() const { const ImVec4& cr = _ClipRectStack.back(); return ImVec2(cr.z, cr.w); }

    // // Primitives
    // IMGUI_API void  AddLine(const ImVec2& a, const ImVec2& b, ImU32 col, float thickness = 1.0f);
    // IMGUI_API void  AddRect(const ImVec2& a, const ImVec2& b, ImU32 col, float rounding = 0.0f, int rounding_corners_flags = ImDrawCornerFlags_All, float thickness = 1.0f);   // a: upper-left, b: lower-right, rounding_corners_flags: 4-bits corresponding to which corner to round
    // IMGUI_API void  AddRectFilled(const ImVec2& a, const ImVec2& b, ImU32 col, float rounding = 0.0f, int rounding_corners_flags = ImDrawCornerFlags_All);                     // a: upper-left, b: lower-right
    // IMGUI_API void  AddRectFilledMultiColor(const ImVec2& a, const ImVec2& b, ImU32 col_upr_left, ImU32 col_upr_right, ImU32 col_bot_right, ImU32 col_bot_left);
    // IMGUI_API void  AddQuad(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& d, ImU32 col, float thickness = 1.0f);
    // IMGUI_API void  AddQuadFilled(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& d, ImU32 col);
    // IMGUI_API void  AddTriangle(const ImVec2& a, const ImVec2& b, const ImVec2& c, ImU32 col, float thickness = 1.0f);
    // IMGUI_API void  AddTriangleFilled(const ImVec2& a, const ImVec2& b, const ImVec2& c, ImU32 col);
    // IMGUI_API void  AddCircle(const ImVec2& centre, float radius, ImU32 col, int num_segments = 12, float thickness = 1.0f);
    // IMGUI_API void  AddCircleFilled(const ImVec2& centre, float radius, ImU32 col, int num_segments = 12);
    // IMGUI_API void  AddText(const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end = NULL);
    // IMGUI_API void  AddText(const ImFont* font, float font_size, const ImVec2& pos, ImU32 col, const char* text_begin, const char* text_end = NULL, float wrap_width = 0.0f, const ImVec4* cpu_fine_clip_rect = NULL);
    // IMGUI_API void  AddImage(ImTextureID user_texture_id, const ImVec2& a, const ImVec2& b, const ImVec2& uv_a = ImVec2(0,0), const ImVec2& uv_b = ImVec2(1,1), ImU32 col = 0xFFFFFFFF);
    // IMGUI_API void  AddImageQuad(ImTextureID user_texture_id, const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& d, const ImVec2& uv_a = ImVec2(0,0), const ImVec2& uv_b = ImVec2(1,0), const ImVec2& uv_c = ImVec2(1,1), const ImVec2& uv_d = ImVec2(0,1), ImU32 col = 0xFFFFFFFF);
    // IMGUI_API void  AddImageRounded(ImTextureID user_texture_id, const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, ImU32 col, float rounding, int rounding_corners = ImDrawCornerFlags_All);
    // IMGUI_API void  AddPolyline(const ImVec2* points, const int num_points, ImU32 col, bool closed, float thickness);
    // IMGUI_API void  AddConvexPolyFilled(const ImVec2* points, const int num_points, ImU32 col);
    // IMGUI_API void  AddBezierCurve(const ImVec2& pos0, const ImVec2& cp0, const ImVec2& cp1, const ImVec2& pos1, ImU32 col, float thickness, int num_segments = 0);

    // // Stateful path API, add points then finish with PathFill() or PathStroke()
    // inline    void  PathClear()                                                 { _Path.resize(0); }
    // inline    void  PathLineTo(const ImVec2& pos)                               { _Path.push_back(pos); }
    // inline    void  PathLineToMergeDuplicate(const ImVec2& pos)                 { if (_Path.Size == 0 || memcmp(&_Path[_Path.Size-1], &pos, 8) != 0) _Path.push_back(pos); }
    // inline    void  PathFillConvex(ImU32 col)                                   { AddConvexPolyFilled(_Path.Data, _Path.Size, col); PathClear(); }
    // inline    void  PathStroke(ImU32 col, bool closed, float thickness = 1.0f)  { AddPolyline(_Path.Data, _Path.Size, col, closed, thickness); PathClear(); }
    // IMGUI_API void  PathArcTo(const ImVec2& centre, float radius, float a_min, float a_max, int num_segments = 10);
    // IMGUI_API void  PathArcToFast(const ImVec2& centre, float radius, int a_min_of_12, int a_max_of_12);                                // Use precomputed angles for a 12 steps circle
    // IMGUI_API void  PathBezierCurveTo(const ImVec2& p1, const ImVec2& p2, const ImVec2& p3, int num_segments = 0);
    // IMGUI_API void  PathRect(const ImVec2& rect_min, const ImVec2& rect_max, float rounding = 0.0f, int rounding_corners_flags = ImDrawCornerFlags_All);

    // // Channels
    // // - Use to simulate layers. By switching channels to can render out-of-order (e.g. submit foreground primitives before background primitives)
    // // - Use to minimize draw calls (e.g. if going back-and-forth between multiple non-overlapping clipping rectangles, prefer to append into separate channels then merge at the end)
    // IMGUI_API void  ChannelsSplit(int channels_count);
    // IMGUI_API void  ChannelsMerge();
    // IMGUI_API void  ChannelsSetCurrent(int channel_index);

    // // Advanced
    // IMGUI_API void  AddCallback(ImDrawCallback callback, void* callback_data);  // Your rendering function must check for 'UserCallback' in ImDrawCmd and call the function instead of rendering triangles.
    // IMGUI_API void  AddDrawCmd();                                               // This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible

    // // Internal helpers
    // // NB: all primitives needs to be reserved via PrimReserve() beforehand!
    // IMGUI_API void  Clear();
    // IMGUI_API void  ClearFreeMemory();
    // IMGUI_API void  PrimReserve(int idx_count, int vtx_count);
    // IMGUI_API void  PrimRect(const ImVec2& a, const ImVec2& b, ImU32 col);      // Axis aligned rectangle (composed of two triangles)
    // IMGUI_API void  PrimRectUV(const ImVec2& a, const ImVec2& b, const ImVec2& uv_a, const ImVec2& uv_b, ImU32 col);
    // IMGUI_API void  PrimQuadUV(const ImVec2& a, const ImVec2& b, const ImVec2& c, const ImVec2& d, const ImVec2& uv_a, const ImVec2& uv_b, const ImVec2& uv_c, const ImVec2& uv_d, ImU32 col);
    // inline    void  PrimWriteVtx(const ImVec2& pos, const ImVec2& uv, ImU32 col){ _VtxWritePtr->pos = pos; _VtxWritePtr->uv = uv; _VtxWritePtr->col = col; _VtxWritePtr++; _VtxCurrentIdx++; }
    // inline    void  PrimWriteIdx(ImDrawIdx idx)                                 { *_IdxWritePtr = idx; _IdxWritePtr++; }
    // inline    void  PrimVtx(const ImVec2& pos, const ImVec2& uv, ImU32 col)     { PrimWriteIdx((ImDrawIdx)_VtxCurrentIdx); PrimWriteVtx(pos, uv, col); }
    // IMGUI_API void  UpdateClipRect();
    // IMGUI_API void  UpdateTextureID();
}

ImDrawListSharedData :: struct {}
ImFont :: struct {}
ImFontConfig :: struct {}

ImGuiFocusedFlags :: enum_flags s32 {
    ChildWindows                  :: 1 << 0;   // IsWindowFocused(): Return true if any children of the window is focused
    RootWindow                    :: 1 << 1;   // IsWindowFocused(): Test from root window (top most parent of the current hierarchy)
    RootAndChildWindows           :: RootWindow | ChildWindows;
}

ImGuiHoveredFlags :: enum_flags s32 {
    Default                       :: 0;        // Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
    ChildWindows                  :: 1 << 0;   // IsWindowHovered() only: Return true if any children of the window is hovered
    RootWindow                    :: 1 << 1;   // IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
    AllowWhenBlockedByPopup       :: 1 << 2;   // Return true even if a popup window is normally blocking access to this item/window
    //AllowWhenBlockedByModal     :: 1 << 3;   // Return true even if a modal popup window is normally blocking access to this item/window. FIXME-TODO: Unavailable yet.
    AllowWhenBlockedByActiveItem  :: 1 << 4;   // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
    AllowWhenOverlapped           :: 1 << 5;   // Return true even if the position is overlapped by another window
    RectOnly                      :: AllowWhenBlockedByPopup | AllowWhenBlockedByActiveItem | AllowWhenOverlapped;
    RootAndChildWindows           :: RootWindow | ChildWindows;
}

#scope_module

#import "Basic";
#import "Math";

#if OS == .WINDOWS {
    #load "windows.jai";
} else {
    #load "unix.jai";
}

// This prints a string using the temporary allocator, and appends a zero at the end.
// Uhh... why not just call tprint and put a "\0" at the end?
tprintz :: (format_string: string, args: .. Any) -> string {
    builder: String_Builder;
    builder.allocator = __temporary_allocator;
    defer free_buffers(*builder);
    
    print_to_builder(*builder, format_string, ..args);
    append(*builder, "\0");

    return builder_to_string(*builder, __temporary_allocator);
} @PrintLike
