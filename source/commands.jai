Command_Info :: struct {
    name : string;
    procedure : ([] string) -> void;
}

// Ideas:
// - load to load files (loading files by drag and drop should effectively run this command)
// - save to save files
// - session_save to write all commands in the session
// - session_load to change  all commands in the session
// - undo to undo previous command
command_list : [..]Command_Info;

init_commands :: () {
    info : Command_Info;
    info.name = "offset";
    info.procedure = tmp_offset;

    array_add(*command_list, info);
}

#scope_file

// @FIXME: We're offsetting polylines and getting polyline boundaries which is really 2 separate operations

tmp_offset :: (args : []string) {
    if args.count != 2 {
        console_add_log("[error] expected exactly 2 arguments");
        return;
    }

    // Generate a interface function which replaces each argument with a handle

    geometry_index : int;
    {
        success : bool;
        remainder : string;
        geometry_index, success, remainder = string_to_int(args[0]);
        if !success {
            console_add_log("[error] first argument is not an int");
            return;
        }
    }

    offset_radius : float;
    {
        success : bool;
        remainder : string;
        offset_radius, success, remainder = string_to_float(args[1]);
        if !success {
            console_add_log("[error] second argument is not a float");
            return;
        }
    }

    if entities.count > geometry_index {
        console_add_log("# offsetting % by % and returning boundaries", geometry_index, offset_radius);
        it := entities[geometry_index];

        if !it.mesh return;

        shape, success := to_Polyline_Soup2(<<it.mesh);

        if !success return;

        offset_polygon := BoostPolygon.offset(*shape, offset_radius);
        if offset_polygon.polygons.count == 0 {
            console_add_log("# result is empty"); // offsetting a line with a negative value gives nothing
            return;
        }
        offset := BoostPolygon.clockwise_boundaries(*offset_polygon);

        // TODO Make this a make_Polyline_Soup2_Entity() function
        entity := New(Polyline_Soup2_Entity);
        entity.type = .POLYLINE_SOUP2;
        entity.mesh = New(Mesh);
        to_Mesh(offset, *entity.mesh);
        geom.buffer_mesh(entity.mesh);
        // entity.ui = ...
        // entity.id = ...
        array_copy(*entity.shape.polylines, offset.polylines);
        for shape.polylines {
            array_copy(*entity.shape.polylines[it_index].points, offset.polylines[it_index].points);
        }
        array_add(*entities, entity);

    } else {
        console_add_log("[error] no geometry with index %", geometry_index);
    }
}