## Next Release

Make imgui.jai handle unix and windows better
Does comma work in the console? What is the enum out of range thing??
The TextColored function in jai-imgui is broken, it doesn't even pass the varargs but also, the api is inconvenient because it uses *u8

- [Bug] Fix the keyboard input capture which blocks the key bindings in an annoying way
- [Bug] Clear button should reset the bounding sphere in the selection mesh
- [Bug] Changing the enabled checkbox on the clipping planes when having an item selection doesn't apply the changes to the item. Found this with only a single item in the list.
- [Bug] Fix the labels appearing outside the clipping box
- [Bug] Fix the occassional deltatime is zero bug

- [Commands] Add a syntax for specifying what command to run when the app starts
- [Commands] Command to select/sort items by type, size, filename etc
- [Commands] Command to compute parameterisation?
- [UI/UX] Sweep drag improvements:
  - When sweeping checkboxes constrain the mouse to the vertical region of the boxes
  - Add a mode to sweeping checkboxes (enabled by holding a modifier?) to toggle the box on entry and exit. User story: animate geometry as you sweep. Generalisation: could have a cooldown rather than just toggling off on exit.
  - Sweep drag should work with scroll wheel in item list, to make this feel really nice I guess we should be updating all the checkboxes intersecting the segment connecting the previous and current position accounting for the scroll wheel
- [UI/UX] Support loading wkt file format to load Polygons in a reasonable way
- [UI/UX] Implement wild cards for file loading
- [UI/UX] Implement an infinite grid, maybe http://asliceofrendering.com/scene%20helper/2020/01/05/InfiniteGrid/
- [UI/UX] Add some options for backface shading, including an obnoxiously visible one for finding holes in meshes
- [UI/UX] Fix issue where holding Ctrl to use the focussed zoom means if we right click to rotate we'll move the focus
- [UI/UX] Don't close the item context menu unless we LMB into viewport
- [UI/UX] Make long lists of items managable in the context menu
- [UI/UX] Improve camera panning
- [UI/UX] Make normals clip

- Windows build devlog
  - Make sure to run the developer console with 64bit settings (x64 Native Tools Command Prompt for VS2019)
  - Run the update_imgui_subrepo_and_rebuild_libs.bat from that console, it generates some changes wrt to what is in the repo
  - Note the warning about deprecated concatenate, should be replaced with join soon
  - Tested that build_examples.jai works in jai-imgui repo
  - Copied imgui.jai and the win/ folder into Garage/src/modules/jai-imgui
  - TODO Make sure to add instructions for updating somewhere



## Backlog

- [UI/UX] Clipping improvements
  - Add plane visualisation, maybe also intersecting the planes
  - Add option to make the clipped geometry render with non-zero opacity
  - Make LMB be the only one to close popups, so you can rotate the view while a popup is open
- [UI/UX] Reload files only if they change, and adjust the fade color if the geometry is unchanged
- [UI/UX] Mode line (bar along bottom) showing hovered mesh stats
- [Rendering] Render aabbs when the box extents are hovered in the UI
- [Rendering] Add option to render normals using only one component
- [Rendering] Think about how normal rendering should interact with opacity, do we want to see normals through the part?
- [UI/UX] Use folding trees in help menu, default to unfolded
- [UI/UX] Add a circling feature pre-screenshot
- [UI/UX] Add a hotloading mode to files (Hotloader module not implemented on linux)
- [UI/UX] Implement simple undo for file loading, would be handy to be able to undo file clobbering...
- [Rendering] Do a better job transparency
- [Rendering] Do something with depth rendering? out_color = vec4(vec3(gl_FragCoord.z), 1.);
- [UI/UX] Load files in a separate thread and report loading progress in the mode line
- [UI/UX] Feedback when refreshing a file gives the same result
- [UI/UX] Define a plane and write the world coordinates of the intersection point by the mouse cursor. Use lmb click drag for measuring
- [UI/UX,Bug] Print boost polygon unsupported message to the console, log more stuff to the console in general
- [Robustness] Add tests for obj loading
- [Camera,Bug] Fix erratic rotation when rotating about the selected axes
- [UI/UX,Camera] Implement perspective projection
  - [UI/UX,Camera] First person camera with strafing and jump/crouch
- [Rendering] Render by index, or adjust colour by index, or make a ripple by point index
- [UI/UX,Rendering] Add clipping plane widgets
- [UI/UX,Camera] Add orbit placement
- [UI/UX,Camera] Make a function to spiral on the bounding sphere and have it activated via a console command
- [UI/UX] Frame rate independent game loop?
- [UI/UX,Bug] Fix obj loading for quad faces
- [UI/UX] :UserConfig Hotload user configurable parameters
- [Bug] Fix sweep dragging check boxes being affected through overlayed ui e.g., colour picker
- [Commands] save_obj <filename> <optional-element-index-list>
- [UI/UX] When we press "Reset Orbit" we should re-place the camera planes
- [UI/UX] Mesh element number/segment number rendering
- [UI/UX] Sliders to select visible range of indices
- [UI/UX] Add a defaults.settings file containing options like default visualisation, scroll velocity, ui response dt's etc
- [UI/UX] Set point-size per-mesh so that point clouds are visible without a non-zero global point size
- [UI/UX] Add a defaults.keymap file containing bindings, also add files for blender, paraview and cloudnc settings
- [UI/UX] Hotload the keymap and settings files
- [UI/UX] Option to render the cumulative vertex number for polyline soups and polygon inner/outer rings or polygon soups
- [UI/UX] Scale zoom speed with scene bounding box when shift is held?
- [UI/UX] Implement a view cube using the Simp module
  - Call SDL_GetWindowWMInfo to get a https://wiki.libsdl.org/SDL_SysWMinfo from which you can get the X11.Window to pass to sim
        SDL_GetWindowWMInfo(window, *wmInfo);
        io.ImeWindowHandle = wmInfo.info.win.window;
- [Performance] Speed up text rendering, it's so slow right now!
- [Performance,Formats] Natively support heightmaps, have native, simple and fast loading file formats
- [UI/UX] Scale the axes according to the bbox of the scene?
- [UI/UX] Arrow keys pan across bounding box?
- [UI/UX] Write the fully pathed filename even for files loaded on the command line
- [UI/UX] Handle infinities in files well
- [Presentation] Explain high-level goals
- [Refactor] Remove geometry module, just load files
- [Meta-programming,Testing] Use @test to tag/run tests
- [Meta-programming,Commands] Autogenerate code for bingings
- [Meta-programming,Commands] Autogenerate ui code for bingings
- [UI/UX] Implement arcball constraints cf. http://graphicsinterface.org/wp-content/uploads/gi1992-18.pdf
- [XXL,UI/UX,Camera] Undo/redo system for camera and other operations
- [UI/UX,Camera] Camera position history/bookmarks with notes/annotations
- [Rendering] Render vertex labels on top of other geometry always
- [UI/UX] Write * to indicate an identical first and last point
- [UI/UX] Sweep drag for removing items from the scene?
- [UI/UX] Click to copy point coordinate in {1.8e} format so that it can be used as a float literal in code
- [UI/UX] Implement sliding to show/hide the terminal
- [UI/UX] Scroll to the bottom of the terminal
- [Build,DevX] Compiled at time in Window, after version?
- [Cleanup] memory management for things returned by boost polygon module, should copy them on jai side and add a function to the bindings which free the mesh :Cleanup_Construction_Destruction:
- [Cleanup] Make the polygon/polyline types use slices, not dynamic arrays, put allocators in the top level
- [Meta-programming] Autogenerate the console registering code to add commands to the console
- [Meta-programming] Generate a list of used ImGui functions, to simplify transitioning to a newer version
- [Rendering] Alternate segment colours (two draw calls?)
- [Rendering] Show grid lines
- [UI/UX] Sounds for a more satifying UI?
- [Commands] Implement geometric equals functions for testing, can be used to compare Jai/C++ implementations
- [Commands] load_obj <filename> to load files (loading files by drag and drop should effectively run this command)
- [Commands] Implement commands to change the render settings on stuff
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
- [UI/UX] Render the axes origin in different color when it's a model origin
- [Bug] ImGui bindings for unix don't write declare CreateContext arguments #c_call
- [Build] Bake fonts into the executable
- [XXL,UI/UX] Buttons with icons which animate when you hover them
- [XXL] Build and add bindings for gmp
- [XXL] Hotload the C++ bindings, and console commands, so you can keep same UI state while you iterate on your code
- [XXL] Hotload jai code so that you can keep state while you change your algorithm
- [Robustness] Just log warnings and ignore the context allocator if it's not malloc, or create a new polygon allocated with malloc if passing to c
- [Rendering] Distribute shaders with source for hot loading/editing them. Pass them lots of unused data then
- [XXL] Place a window (circle/square) with a local camera in it that can be oriented to look around the scene
- [UI/UX] Hover over UI element (button/checkbox) and press a key to bind that key to it, display the bound keys in a list somewhere
- [UI/UX] When hovering over items in the scene make the others/overlapping ones transparent
- [XXL,UI/UX] Suggested values when transforming an item
- [UI/UX] Add a button to capture a screenshot, look at the Jai Clipboard module
- [XXL,UI/UX] Think about how to do literate programming in Jai, use this to generate the user documentation. Maybe with notes attached to procedures or decalarations? It would be cool to generate context specific help windows using this information in comments/notes somehow, maybe a local variable matching some pattern get processed by a meta program?
- [XXL] Think about a plugin system where you write bindings for c++ libraries and benefit from Jai introspection e.g., bind to C++ datastructures/algorithms, and auto generate UI for Jai versions of those for fast experimentation/UI generation
