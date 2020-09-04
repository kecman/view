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

    if geometries.count > geometry_index {
        console_add_log("# offsetting % by % and returning boundaries", geometry_index, offset_radius);
        it := geometries[geometry_index];

        if #complete it.type == {
            case geom.Renderable_Geometry_Type.POLYLINE2;
                p := cast(*geom.Renderable_Polyline2) it;

                offset := BoostPolygon.offset(*p.geometry, offset_radius);
                if offset.polygons.count == 0 {
                    console_add_log("# result is empty"); // offsetting a line with a negative value gives nothing
                    return;
                }

                boundary := BoostPolygon.clockwise_boundaries(*offset);
                renderable := New(geom.Renderable_Polyline_Soup2);
                renderable.filename = "";
                array_copy(*renderable.geometry.polylines, boundary.polylines);
                geom.buffer_polyline_soup(renderable);
                array_add(*geometries, renderable);

            case geom.Renderable_Geometry_Type.POLYLINE_SOUP2;
                p := cast(*geom.Renderable_Polyline_Soup2) it;
                offset := BoostPolygon.offset(*p.geometry, offset_radius);
                if offset.polygons.count == 0 {
                    console_add_log("# result is empty"); // offsetting a line with a negative value gives nothing
                    return;
                }

                boundary := BoostPolygon.clockwise_boundaries(*offset);
                renderable := New(geom.Renderable_Polyline_Soup2);
                renderable.filename = "";
                array_copy(*renderable.geometry.polylines, boundary.polylines);
                geom.buffer_polyline_soup(renderable);
                array_add(*geometries, renderable);
        }
    } else {
        console_add_log("[error] no geometry with index %", geometry_index);
    }
}