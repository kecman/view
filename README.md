View
====

A simple geometry processing tool.

Eventually I want to make this into a handy environment for developing geometric algorithms and having them callable/composable via console commands

Written in Jonathan Blow's [Jai programming language](https://youtu.be/TH9VCN6UkyQ), currently in closed beta as of January 2021.

## Features

Currently very basic:

- Load .obj files representing polylines, polygons or meshes
- Change colors of items in the scene
- Some console commands for manipulating polylines/polygons are available
- Toggle console visibility with '`' (backtick)
- Cycle vertex rendering with 'v'
- Cycle line rendering with 'l'

See PLAN.md for a roadmap

## Notes
- Currently linux only
- Boost Polygon C++ library not yet available  so some features are disabled (I need to sort out git lfs stuff...)