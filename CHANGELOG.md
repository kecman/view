# Unreleased

- Fixed rotation not working properly when zoomed in

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
