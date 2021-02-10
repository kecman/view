main :: ()
{
    basic_language_demo();
    polygon_demo();
    context_demo();
}

basic_language_demo :: ()
{
    demo_markers();

    // Basics
    {
        Machine_Limits :: struct {
            min_rpm : float = 100.;
            max_rpm := 8000.;
        }

        CNC_Machine :: struct {
            post          : Post_Processor = .HAAS;
            name          : string = "vf2";
            limits        : Machine_Limits;
            settings      : Settings = .RAPID_50PC;
            table_extents : Vector3 = .{1000, 1000, 1000};
            table_extents.z = 666;
        }

        Post_Processor :: enum { HAAS; MAZAK; SIEMENS; FANUC; }

        Settings :: enum_flags {
            ALL_OVERRIDE_LOCKS     :: SPINDLE_OVERRIDE_LOCK | FEEDRATE_OVERRIDE_LOCK;
            RAPID_50PC             :: 0b001;
            SPINDLE_OVERRIDE_LOCK  :: 0b010;
            FEEDRATE_OVERRIDE_LOCK :: 0b100;
        }

        VF2 :: CNC_Machine.{limits=.{0, 8000}, settings = cast(Settings)7};      // This is constant
        print("I see you have a\n%2\n%1\n",                                      // Format string can reorder arguments
              get_opinion(VF2),                                                  // Try commenting this
              formatStruct(VF2, 0, long_form_separator_between_fields = ";\n")); // Adjustable format

        mazak := VF2;
        mazak.post = .MAZAK;
        mazak.name = "i500";
        print("I see you have a\n%2\n%1\n",
              get_opinion(mazak),
              formatStruct(mazak, 0, long_form_separator_between_fields = ";\n"));

        get_opinion :: (using machine : CNC_Machine) -> string {
            opinion : string = ---;
            // Switch statement reuses keywords
            if #complete post == {
                case .HAAS;    #through; // Try commenting this
                case .FANUC;   opinion = "This is a cool machine\n";
                case .MAZAK;   opinion = "Only dweebs use this machine\n";
                case .SIEMENS; opinion = "Only ultra-dweebs use machine\n";
            }
            return opinion;
        }
    }

    // Simple for loop
    {
        numbers : [..]int;
        array_add(*numbers, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
        old_count := numbers.count;

        print("A %\n", numbers);

        for *n, i : numbers {
            <<n += 10;
        }

        print("\nB %\n", numbers);

        for numbers {
            if it_index == 0 continue;
            if it % 2   == 0 remove it;
        }

        print("\n");
        for < numbers print("C [%] %\n", it_index, it);
    }
}


polygon_demo :: ($write_markers := true)
{
    #if write_markers demo_markers();

    //  y
    //  ^
    //  7 +------------<------------+
    //    |                         |
    //    | 5 +-->---+   +-->---+   |
    //    |   |      |   |      |   |
    //    |   |      |   |      |   |
    //    | 2 +--<---+   +--<---+   |
    //    |   2      5   7     10   |
    //  0 +------------>------------+
    //    0                         12 --> x
    //
    make_polygon_a :: () -> Polygon {
        using polygon : Polygon;
        array_add(*outer_ring.points, .{0, 0}, .{12, 0}, .{12, 7}, .{0, 7}, .{0, 0});

        inner_ring_0 := array_add(*inner_rings);
        inner_ring_1 := array_add(*inner_rings);
        array_add(*inner_ring_0.points, .{2, 2}, .{2, 5}, .{5, 5}, .{5, 2}, .{2, 2});
        array_add(*inner_ring_1.points, .{7, 2}, .{7, 5}, .{10, 5}, .{10, 2}, .{7, 2});

        return polygon;
    }

    // Make a simple polygon
    polygon := make_polygon_a();
    print("polygon = %\n", polygon);

    // Compute bounding box
    polygon_box := bounding_box(polygon);
    print("polygon_box = %\n", polygon_box);

    // Compute area
    polygon_area := area(polygon);
    assert(polygon_area == 66.);
    printv(#code polygon_area);
}

context_demo :: ()
{
    demo_markers();

    print(">>> A\n");
    polygon_demo(false);

    new_context : Context;
    push_context new_context {
        format_float := *context.print_style.default_format_float;
        format_float.mode = .SCIENTIFIC;

        print(">>> B\n");
        polygon_demo(false);
    }

    print(">>> C\n");
    polygon_demo(false);
}

#scope_file

demo_markers :: (loc := #caller_location) #expand
{
    print("\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
    print("Demo at %:%\n\n", loc.fully_pathed_filename, loc.line_number);
    `defer print("\n<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
}

#import "Basic";
#import "Math";
#import "geometry";
#load "carpet.jai";

// #run main();
