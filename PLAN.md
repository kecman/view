## Soon
- [Build] Distribution stuff, make a single executable if possible or executable + boost dll, bake fonts into the executable at least.
- Option to render the cumulative vertex number for polyline soups and polygon inner/outer rings or polygon soups
- Options on what options to include in the vertex cycling
- Render vertex labels on top of other geometry always
- Support loading wkt file format, so we can load Polygons in a reasonable way
- Implement commands to change the render settings on stuff
- [Testing] [Meta-programming] Use @test to tag/run tests
- [Commands] [Meta-programming] Autogenerate code for bingings
- [Commands] [Meta-programming] Autogenerate ui code for bingings
- [Bug] Show points in the specific entity, not on the mesh, so this works better with polygons
- [Bug] Fix vertex numbering with meshes
- Scale zoom speed with scene bounding box when shift is held?

## Backlog
- [Performance] Speed up text rendering, it's so slow right now!
- [XXL] Build and add bindings for gmp
- [XXL] Hotload the C++ bindings, and console commands, so you can keep same UI state while you iterate on your code
- [XXL] Hotload jai code so that you can keep state while you change your algorithm
- Implement geometric equals functions for testing, can be used to compare Jai/C++ implementations
- Don't pass pointers for arguments that aren't modified
- [Rendering] Alternate segment colours (two draw calls?)
- [UI/UX] Add a defaults.settings file containing options like default visualisation, scroll velocity, ui response dt's etc
- [UI/UX] Add a defaults.keymap file containing bindings, also add files for blender, paraview and cloudnc settings
- [UI/UX] Dynamically generate some UI windows a la imgui_inspector.jai
- [UI/UX] Hold shift to change size of arcball, and project across x/y direction so you can do full 90degree rotations of the part, draw regions in the far plane and cicle on the near plane
- [UI/UX] Implement sliding to show/hide the terminal
- [UI/UX] Scroll to the bottom of the terminal
- [UI/UX] If file is hovered make it flash to white so it's easy to find
- [UI/UX] Implement a view cube
- [UI/UX] Implement arcball constraints cf. http://graphicsinterface.org/wp-content/uploads/gi1992-18.pdf
- [UI/UX] Camera position history/bookmarks with notes/annotations
- Compiled at time in Window, after version?
- [Cleanup] memory management for things returned by boost polygon module, should copy them on jai side and add a function to the bindings which free the mesh :Cleanup_Construction_Destruction:
- Transparency with order as it is in the entity list
- [Cleanup] Make the polygon/polyline types use slices, not dynamic arrays, put allocators in the top level
- [Meta-programming] Autogenerate the console registering code to add commands to the console
- [Meta-programming] Generate a list of used ImGui functions, to simplify transitioning to a newer version
- Sort by time loaded
- Write * to indicate an identical first and last point
- Mode line showing the style info etc
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
