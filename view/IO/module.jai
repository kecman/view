geom :: #import "Geom";

load_obj_polyline2 :: (filename : string) -> *geom.Polyline2 #must { // (filename: string) -> [] *geom.Polyline2 {

    handler: Text_File_Handler;
    handler.do_version_number = false;
    defer deinit(*handler);

    start_file(*handler, "load_obj", filename, "load_obj_polyine2", false);
    if handler.failed {
        print("Error (%:%): Unable to find my own executable?!\n", #file, #line); // @Cleanup proper logging
        exit(1);
    }

    polyline := New(geom.Polyline2);

    while true {
        line, found := consume_next_line(*handler);
        if !found break;

        key_name, rhs := break_by_spaces(line);
        if !rhs {
            error(handler, "Expected a space after the key specifier.\n");
            continue;
        }

        parse_vertex :: (handler : *Text_File_Handler, str : string) -> bool, geom.Polyline2.Point {
            str_x, str_yz := break_by_spaces(str);
            str_y, str_z := break_by_spaces(str_yz);
            return true, make_vector2(string_to_float(str_x), string_to_float(str_y));
        }

        if key_name == {
            case "v";
                success, vertex := parse_vertex(*handler, rhs);
                if !success continue;
                array_add(*polyline.points, vertex);
            case "vn"; // @Incomplete
            case "vt"; // @Incomplete
            case "l"; // @Incomplete
            case "f"; // @Incomplete
            case;
                print("found unknown: %\n", rhs);
                error(handler, "Found unexpected '%'.\n", rhs);
                continue;
        }
    }

    // print("%\n", <<polyline);
    // for polyline.points print("%\n", it);
    geom.buffer_polyline(polyline);

    return polyline;
}

#scope_file

#import "Text_File_Handler";
#import "Basic";
#import "System";  // To get the executable's path.
#import "String";
#import "Math";