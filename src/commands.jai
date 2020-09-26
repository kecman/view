Command_Info :: struct {
    name : string;
    procedure : ([] string) -> void;
}

command_list : [..]Command_Info;

init_commands :: () {
    {
        info : Command_Info;
        info.name = "offset";
        info.procedure = tmp_offset;
        array_add(*command_list, info);
    }

    {
        info : Command_Info;
        info.name = "clockwise_boundaries";
        info.procedure = tmp_clockwise_boundaries;
        array_add(*command_list, info);
    }
}

#scope_file

get_geometry_index :: (arg : string) -> int, bool #must {

    result, success, remainder := string_to_int(arg);
    if !success {
        console_add_log("[error] first argument is not an int");
        return -1, false;
    }

    if result < 0 || result >= entities.count {
        console_add_log("[error] invalid/out of range geometry index");
        return -1, false;
    }

    return result, true;
}

tmp_clockwise_boundaries :: (args : []string) {
    if args.count != 1 {
        console_add_log("[error] expected exactly 1 argument");
        return;
    }

    geometry_index, ok_geometry_index := get_geometry_index(args[0]);
    if !ok_geometry_index return;


    it := entities[geometry_index];

    if it.type != .POLYGON_SOUP2 {
        console_add_log("[error] offset not supported for entity type %", it.type);
        return;
    }

    polygon_soup2_entity := cast(*Polygon_Soup2_Entity) it;

    boundary := BoostPolygon.clockwise_boundaries(*polygon_soup2_entity.shape);
    if boundary.polylines.count == 0 {
        console_add_log("# result is empty");
        return;
    }

    // TODO Make this a make_Polyline_Soup2_Entity() function
    // :Cleanup_Construction_Destruction:
    entity := New(Polyline_Soup2_Entity);
    entity.type = .POLYLINE_SOUP2;
    ok : bool;
    entity.mesh, ok = to_Mesh(boundary);
    geom.buffer_mesh(*entity.mesh);
    entity.shape = boundary;

    array_add(*entities, entity);
}

tmp_offset :: (args : []string) {
    if args.count != 2 {
        console_add_log("[error] expected exactly 2 arguments");
        return;
    }

    geometry_index, ok_geometry_index := get_geometry_index(args[0]);
    if !ok_geometry_index return;

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

    entity := New(Polygon_Soup2_Entity);
    entity.type = .POLYGON_SOUP2;
    ok : bool;
    entity.mesh, ok = to_Mesh(offset_polygon);
    geom.buffer_mesh(*entity.mesh);
    entity.shape = offset_polygon;

    array_add(*entities, entity);
}