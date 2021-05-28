***** Fix camera orbit positioning zoom level when
***** Don't screentone backfaces when wireframe mode (or transparency?) is on

# Version: v0.1.0, Unreleased

- Added a more joyful background shader enabled by default [ty [@LoganBarnes](https://github.com/LoganBarnes)]
  - Changed the default label color so it works well on both both white and grey backgrounds
  - Future work will hotload this shader and the provide inputs expected by Shadertoy
  - The boring solid color option is still available in settings (press Shift+h to access)
- Added a screentone effect when rendering a backfacing triangle (press RMB item name to access)
- Added normal rendering with options to set color and length in the item context menu
  - Normal rendering also works for oriented point clouds loaded from an obj file containing v, vn and p codes
- Added a new UI idiom in which bindings will affect the currently hovered unselected item, all selected items (Ctrl+LMB selects a item)
  - Added a binding to cycle normals visibility (n) using this idiom
  - Added a binding to cycle opacity 20%/50%/100% (o) using this idiom
  - Changed the binding for reloading items (F5) to follow this idiom
  - ***** Changed the bindings for cycling point size (p) to follow this idiom
  - ***** Changed the bindings for cycling line width (l) to follow this idiom
  - ***** Changed the binding to popup the item context menu (RMB) to follow this idiom, also added many more options to this context menu
- Added a binding to select/deselect all items (Ctrl+a)
- Added a binding to toggle/complement the current item selection (Alt+a)
- Changed binding to set orbit position in user selection mode from Ctrl+MMB to Ctrl+RMB
- Changed user selection queries to only compute when the result will be used rather than every frame
- Fixed a bug where user selection did not correctly account for transformed (shifted) items
- Fixed a bug where user selection was not considered when the scene view is resized causing it to be clipped sometimes for transformed (shifted) items
- Fixed a bug where reloading an item failed to preserve the world from model transform
- Changed default point size on startup to be 0, when point clouds are inferred they will have a point size of 2
- Improved the item list UI
  - Improved the colors generated from filenames **** generated from the filenames only to match across machines, old behaviour is available in settings (Shift+h to access)
  - Moved the item index to come just before the filename (makes the item list UI jump around less)
  - Swapped the visiblity checkbox with the Remove/Clear buttons

# Version: v0.0.6, 17 May 2021

- Added initial version of user selection:
  - User selection is enabled if the "User selection" item is set to visible in the item list
  - Ctrl+LMB adds/removes the vertex closest to a ray shot under the cursor to the user selection
  - Vertex selection works using brute force search so only items with <= 10,000 vertices are searched by default
  - The search limit is conservative and can be changed in the user selection context menu (press RMB on "User selection" text to access)
  - If multiple vertices have the same distance from the ray one is arbitrarily chosen
  - Ctrl+MMB shifts the camera look/orbit position to the closest vertex while preserving the look direction
- Added file load time to item context menu and added a visual fade to indicate a file load occurred
- Added a quick toggle between display modes with a RMB click on the item color picker
- Added simple transparency rendering: opaque items are rendered before transparent ones
- Fixed a bug, introduced in v0.0.5, where the setting to update the camera to fit dropped items to the screen was not respected
- Fixed flickering UI when removing items from the scene
- Changed the hovered item to always render ignoring the depth buffer so that hovered items are easier to find
- Changed item list to display only the filename rather than the fully pathed filename (which is still visible in the item context menu)
- Changed reloading multiple items to preserve the selection, this makes reloading the same selection easier (a common use case)
- Changed settings to be hidden by default (press Shift+h to toggle them, press h for help)

# Version: v0.0.5, 12 May 2021

- Improved the UI by organising settings under collapsing headers
- Improved the world axes rendering and moved it to the bottom left of the screen
- Added UI to translate items via the item context menu
- Added UI to reload items via the item context menu, multiple items can be selected using Ctrl+LMB and batch reloaded
- Added F5 key-binding to reload currently selected items in the item list
- Added an overwrite option for handling dropped files with the same name as an existing item
- Changed default for option to preserve the camera up direction when snapping to axis aligned look directions from on to off

# Version: v0.0.4, 23 April 2021

- Improved the camera implementation to improve the feel of the zoom controls
- Changed mouse wheel zooming to zoom into/out from the location where the mouse is pointing
- Fixed an issue where fitting the visible entities to the screen was slow for large entities
- Added an option, when item visibility is toggled, to update the camera to fit all items to the screen, off by default
- Added an option, when files are dropped, to update the camera to fit all items to the screen, on by default
- Added an option to preserve the camera up direction when snapping to axis aligned look directions, on by default
- Added a constraint to prevent the camera from zooming out further than necessary to view the entire scene, on by default
- Added configurable behaviour for loading files with the same path, by default files are appended scene and display with an incremented generation index
- Changed the item context menu to display the fully pathed filename, only the filename (and generation index) is shown in the items list
- Changed the item context menu to display the axis aligned bounding box of an item
- Changed the key-binding to close the application to Ctrl+Shift+q, since it was easy to loose work by accidently pressing Esc
- Most settings/options mentioned above can be changed at runtime in a 'User settings' section (press h for help). Future work will persist user settings across sessions

# Version: v0.0.3, 5 April 2021

- Fixed camera rotation not working properly when zoomed in
- Fixed point numbering for 3D polylines inferred from .obj files
- Fixed text positioning for 3D polylines
- Improved error reporting when loading invalid .obj files
- Added text label options (floating point format, text scale and colour) accessible via global settings menu (press h for help)
- Added an option to increase the label rendering limit, a warning message is printed if this exceeds 2000 (text rendering is still super slow)
- Changed the default to point size to 2 from 0 so visualising point clouds is more convenient
- Changed Shift+LMB to rotate about the currently selected camera rotation axis
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
