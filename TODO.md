## Soon
- 3D mesh shading and lights in the scene
- Use @test to tag/run tests
- Autogenerate code for bingings
- [Bug] Show points in the specific entity, not on the mesh, so this works better with polygons
- [Bug] Fix vertex numbering with meshes
- [Bug] Fix crash when loading a toolpath .obj
- If file is hovered make it flash to white so it's easy to find

## Backlog
- build_debug and build_release with proper llvm options
- Hot load the C++ bindings, and console commands, so you can keep same UI state while you iterate on your code
- Don't pass pointers for arguments that aren't modified
- Alternate segment colours (two draw calls?)
- Compiled at time in Window, after version?
- Implement sliding to show/hide the terminal
- Scroll to the bottom of the terminal
- Cleanup memory management for things returned by boost polygon module, should copy them on jai side and add a function to the bindings which free the mesh :Cleanup_Construction_Destruction:
- Transparency with order as it is in the entity list
- Cleanup construction/destruction: make functions to do that
- Support polygons and polygon soups, and do convex decomposition for rendering
- Support loading wkt file format
- Cleanup text rendering, it's so slow right now!
- Make the polygon/polyline types use slices, not dynamic arrays, put allocators in the top level
- Autogenerate the console registering code to add commands to the console
- Sort by time loaded
- Distribution stuff, how to make this a single executable? statically link?
- Write * to indicate an identical first and last point
- Mode line showing the style info etc
- Custom key-bindings and sensitivity of parameters, dynamically generate UI for this? and save to the text file
- Understand and use context stuff (logging, assertions, allocators), watch https://youtu.be/ciGQCP6HgqI
- Give each polyline a number 1-9 then pressing that number before some modifier for colour/vertex etc only modifies that one, number 0 means everything?
- Toggle fullscreen/maximise
- Some kind of ui cooldown for removing files? So that you don't loose track of what's being deleted
- Zoom to origin
- Show grid lines and label
- Transparent imgui window so UI is like Fusion?
- Distribute shaders with source for hot loading/editing them. Pass them lots of unused data then
- Fix orbit/rotation location when many files are loaded but some aren't visible
- Just log warnings and ignore the context allocator if it's not malloc, or create a new polygon allocated with malloc if passing to c
- Extend the imgui_inspector example to allow you to drag+drop jai files and have show you all the types in the file
- Use automatic differentiation in shape generation
- Sounds for a more satifying UI?
- Implement a view cube
- Implement arcball constraints cf. http://graphicsinterface.org/wp-content/uploads/gi1992-18.pdf
- [Commands] save_obj <filename>, load_obj <filename> to load files (loading files by drag and drop should effectively run this command)
- [Commands] save_wkt <filename>, load_wkt <filename> to load files (loading files by drag and drop should effectively run this command)
- [Commands] save_session <filename>, load_session <session> to write all commands in the session
- [Commands] make_float/make_xform/make_mesh
- [Commands] xform <id> <transform>
- [Commands] edit <id> to popup inspection ui
- [Commands] assign x # assigns x to the previous result?
- [Commands] undo/redo
- [Bindings] Improve API, these accept pointers because the c++ functions take const-ref args
- [Bindings] Can these declarations have notes? Check Preload.jai?
- [Bindings] Write a function to print in wkt format? simpler custom format?
- [Bindings] Add libIGL bindings?
- [Bug] Fix camera frustrum contain all visible items
- [Bug] Fix memory leaks, need to use a new version of valgrind for --keep-debuginfo=yes option but it seems like getting to show line numbers properly isn't working
- [Bug] ImGui bindings for unix don't write declare CreateContext arguments #c_call

## Miscellaneous

Script to build imgui as a library:

```
    # Build a static and dynamic library and copy to jai project.
    # Note: Using -fno-exceptions since without it linker called by Jai can't find _Unwind_Resume
    gcc -fno-exceptions -Wall -c *.cpp
    ar rcs ImGui.a *.o
    gcc -fno-exceptions -shared -fPIC -Wall -o ImGui.so  imgui.cpp imgui_draw.cpp imgui_demo.cpp 
    cp ImGui.a ImGui.so ~/Dropbox/jai/modules/ImGui/linux/.
```
