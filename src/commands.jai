Command_Info :: struct {
    name : string;
    procedure : ([] string) -> void;
}

command_list : [..]Command_Info;

init_commands :: () {
    info : Command_Info;
    info.name = "offset";
    info.procedure = tmp_offset;

    array_add(*command_list, info);
}

#scope_file

// @Cleanup We're offsetting polylines and getting polyline boundaries which is really 2 separate operations

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

    // @CompilerBug I don't see the entities global in gdb here??

    if entities.count > geometry_index {
        it := entities[geometry_index];

        if it.type != .POLYLINE_SOUP2 {
            console_add_log("[error] offset not supported for entity type %", it.type);
            return; // @Incomplete support polygons
        }

        console_add_log("# offsetting % by % and returning boundaries", geometry_index, offset_radius);

        polyline_soup2_entity := cast(*Polyline_Soup2_Entity) it;

        offset_polygon := BoostPolygon.offset(*polyline_soup2_entity.shape, offset_radius);
        if offset_polygon.polygons.count == 0 {
            console_add_log("# result is empty"); // offsetting a line with a negative value gives nothing
            return;
        }

        print_Polygon_Soup(offset_polygon);

        ok : bool;

        {
            entity := New(Polygon_Soup2_Entity);
            entity.type = .POLYGON_SOUP2;
            entity.mesh, ok = to_Mesh(offset_polygon);
            geom.buffer_mesh(*entity.mesh);
            entity.shape = offset_polygon;
            array_add(*entities, entity);
        }

        offset := BoostPolygon.clockwise_boundaries(*offset_polygon);

        print_Polyline_Soup(offset);

        // TODO Make this a make_Polyline_Soup2_Entity() function
        // :Cleanup_Construction_Destruction:
        entity := New(Polyline_Soup2_Entity);
        entity.type = .POLYLINE_SOUP2;
        entity.mesh, ok = to_Mesh(offset);
        geom.buffer_mesh(*entity.mesh);
        entity.shape = offset;

        // // entity.id = ...
        // array_copy(*entity.shape.polylines, offset.polylines);
        // for polyline_soup2_entity.shape.polylines {
        //     array_copy(*entity.shape.polylines[it_index].points, offset.polylines[it_index].points);
        // }

        array_add(*entities, entity);

    } else {
        console_add_log("[error] no geometry with index %", geometry_index);
    }
}