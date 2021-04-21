# Version: v0.0.4, Unreleased

- Improved the camera implementation to improve the feel of the zoom controls
- Changed mouse wheel zooming to zoom into/out from the location where the mouse is pointing
- Fixed an issue where fitting the visible entities to the screen was slow for large entities
- When visibility of any item is changed the camera is updated to fit items to the screen
- When files are dropped into `garage` the camera is updated to fit all items to the screen
- Added an option to make drag zooming zoom into/out from the location where the RMB was pressed, off by default
- Added a constraint to prevent the camera from zooming out further than necessary to view the entire scene
- Added option to change user preferences (including some settings mentioned above) in a running session* (press h for help)

 (*) Future work will persist user preferences across sessions

# Version: v0.0.3, 5 April 2021

- Fixed camera rotation not working properly when zoomed in
- Fixed point numbering for 3D polylines inferred from .obj files
- Fixed text positioning for 3D polylines
- Improved error reporting when loading invalid .obj files
- Added text label options (floating point format, text scale and colour) accessible via global settings menu (press h for help)
- Added an option to increase the label rendering limit, a warning message is printed if this exceeds 2000 (text rendering is still super slow)
- Changed the default to point size to 2 from 0 so visualising point clouds is more convenient
- Changed shift+LMB to rotate about the currently selected camera rotation axis
- Pressing F11 toggles between fullscreen and windowed modes

# Version: v0.0.2, 28 March 2021

- Holding shift while zooming/rotating/panning speeds up that operation, holding alt slows it down
- Added point cloud .obj file support*
- Added notes on mouse bindings to the help menu (press h for help)
- Added a binding to reset the camera if something screws up (press h for help)
- Changed the default speed of RMB drag zooming to make it faster
- Changed camera near plane positioning to reduce strange clipping when focusing items
- Fixed `garage` not starting up unless started from its containing folder, adding the containing folder to your `$PATH` now works as expected
- Fixed visible entities not fitting to the screen properly in some cases
- Fixed zooming with mouse scroll not registering unless the cursor was moving
- Fixed sweep-toggle-able checkboxes not toggling the initial checkbox if the sweep started within it

(*) Note: you won't see anything unless you cycle point size to a non-zero value (press h for help)

# Version: v0.0.1, 21 March 2021

- Load simple obj files with v,vn,f,l codes. If only l codes are present a polyline soup entity type is inferred, otherwise a mesh type is inferred
- Load files by drag and drop or passing filenames as arguments on the command line
- Entity list panel with sweep-draggable visibility checkboxes, color selection and per-item options menu
- Mesh rendering options of solid color, Blinn-Phong and normal shading
- Text rendering options for point indices and coordinates, currently restricted to 2000 points maximum
- Basic console with bindings to polyline/polygon offset implemented by Boost Polygon
- Auto-color selection for loaded entities using a hash of the filename
- Orthographic camera with axis-aligned look direction buttons
- Camera rotation buttons and key bindings with configurable axis of rotation
- Selectable background and mesh colors
- Togglable world coordinate axes
