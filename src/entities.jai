Entity_Type :: enum {
    UNKNOWN;
    POLYLINE_SOUP2;
    POLYLINE_SOUP3;
    POLYGON_SOUP;
    MESH;
}

Entity :: struct {
    type : Entity_Type = .UNKNOWN;

    is_visible := true;
    is_visible_sweep_hovered := false;
    is_selected := false;
    is_hovered := false;

    render_info : Render_Info;
    display_info : Display_Info;
    mesh : Mesh;

    using_default_vertex_label_style : bool = true;
    fully_pathed_filename : string;
    loaded_filetime : u64;
    generation_index : int; // entities with the same fully pathed_filename will increment this
}

Polyline_Soup2_Entity :: struct {
    using base : Entity;
    type = .POLYLINE_SOUP2;

    shape : Polyline_Soup2;
}

Polyline_Soup3_Entity :: struct {
    using base : Entity;
    type = .POLYLINE_SOUP3;

    shape : Polyline_Soup3;
}

Polygon_Soup_Entity :: struct {
    using base : Entity;
    type = .POLYGON_SOUP;

    shape : Polygon_Soup;
}

Mesh_Entity :: struct {
    using base : Entity;
    type = .MESH;
}

deinit :: (base : *Entity)
{
    if #complete base.type == {
        case .UNKNOWN;
            // do nothing

        case .POLYLINE_SOUP2;

            entity := cast(*Polyline_Soup2_Entity)base;
            deinit(*entity.mesh);
            deinit(*entity.shape);

        case .POLYLINE_SOUP3;

            entity := cast(*Polyline_Soup3_Entity)base;
            deinit(*entity.mesh);
            deinit(*entity.shape);

        case .POLYGON_SOUP;

            entity := cast(*Polygon_Soup_Entity)base;
            deinit(*entity.mesh);
            deinit(*entity.shape);

        case .MESH;

            entity := cast(*Mesh_Entity)base;
            deinit(*entity.mesh);
    }

    if base.render_info.vbo glDeleteBuffers(1, *base.render_info.vbo);
    if base.render_info.ibo glDeleteBuffers(1, *base.render_info.ibo);
    base.render_info.vbo = 0;
    base.render_info.ibo = 0;
    base.render_info.is_dirty = true;

    free(base.fully_pathed_filename);
}

entity_filename :: (using entity : Entity, with_generation_index : bool, with_short_filename : bool, with_loaded_time : bool) -> string {
    name_text := fully_pathed_filename;
    if with_short_filename {
        Push_Temporary();
        path := parse_path(fully_pathed_filename);
        if path.words.count {
            name_text = path.words[path.words.count - 1];
        }
    }

    index_text := " ";
    if generation_index != 0 && with_generation_index {
        index_text = tprint("<%> ", generation_index);
    }

    time_text := "";
    time_separator := "";
    if with_loaded_time {
        time_text = filetime_to_readable_date(loaded_filetime);
        time_separator = "@ ";
    }

    return tprint("%1%2%3%4", name_text, index_text, time_separator, time_text);
}

color_from_path :: (path : string) -> Vector4 {
    if path.count == 0 {
        return .{1., 1., 1., 1.};
    }

    to_hash : string;
    if app.settings.color_from_path_behaviour == {
        case .FILENAME_ONLY;
            parsed := parse_path(path);
            to_hash = parsed.words[parsed.words.count - 1];
        case .FULLY_PATHED_FILENAME;
            to_hash = path;
    }

    n := get_hash(to_hash);
    m := get_hash(n);

    h := (cast(float)(n % 257) / 256);
    s := 1.;
    v := (cast(float)(m % 257) / 256) * .3 + .7;

    r, g, b : float;
    ImGui.ColorConvertHSVtoRGB(h, s, v, *r, *g, *b);

    return make_vector4(r, g, b, 1.);
}

load_entity_from_file :: (filename : string) -> *Entity {
    // @Incomplete: support polygon types using wkt format and improve reporting here
    log("Loading file '%'... ", filename);
    mesh := load_obj(filename);

    if !mesh.positions.count {
        log("Skipped (empty vertex position data)\n");
        deinit(*mesh);
        return null;
    }

    Common_Init :: () #expand {
        `entity.mesh = mesh;
        `entity.fully_pathed_filename = copy_string(filename);
        `entity.loaded_filetime = get_current_file_time();

        log("Inferred entity type '%'", `entity.type);
    }

    if #complete mesh.geometry_format == {
        case .LINES;

            bbox := bounding_box(mesh);
            if diagonal(bbox).z == 0 {

                entity := New(Polyline_Soup2_Entity);
                shape, ok := to_Polyline_Soup2(mesh);
                assert(ok);
                entity.shape = shape;

                Common_Init();
                entity.display_info.wireframe_visible = true;
                entity.display_info.wireframe_width = 1;
                entity.display_info.wireframe_color = color_from_path(filename);

                return entity;
            } else {

                entity := New(Polyline_Soup3_Entity);
                shape, ok := to_Polyline_Soup3(mesh);
                assert(ok);
                entity.shape = shape;

                Common_Init();
                entity.display_info.wireframe_visible = true;
                entity.display_info.wireframe_width = 1;
                entity.display_info.wireframe_color = color_from_path(filename);

                return entity;
            }

        case .TRIANGLES;

            entity := New(Mesh_Entity);

            Common_Init();
            entity.display_info.surface_visible = true;
            entity.display_info.surface_color = color_from_path(filename);

            return entity;

        case .POINTS;

            entity := New(Mesh_Entity);

            Common_Init();
            entity.display_info.points_visible = true;
            entity.display_info.points_size = 2;
            entity.display_info.points_color = color_from_path(filename);

            return entity;

        case .UNKNOWN;

            log("Skipped (unsupported geometry type %)\n", mesh.geometry_format);
            deinit(*mesh);
            return null;
    }
}

Closest_Vertex_On_Entity :: struct {
    vertex_position : Point3;
    vertex_index : int = -1;
    entity_index : int = -1;
}

find_closest_vertex_on_visible_entities :: () -> Closest_Vertex_On_Entity {

    view_from_clip := inverse(make_orthographic_projection_matrix(app.camera));
    world_from_view := inverse(make_look_at_matrix(app.camera));
    transform := world_from_view * view_from_clip;
    inverse_transpose := transpose(inverse(transform));

    ray : Ray3 = ---;
    ray.origin = (transform * make_vector4(to_ndc(make_Vector2(io().MousePos)), -1., 1.)).xyz;
    ray.direction = (inverse_transpose * make_vector4(0., 0., 1., 0.)).xyz;
    check := normalize_or_zero(*ray.direction);
    assert(check != 0.); // @Robustness: handle this error

    result : Closest_Vertex_On_Entity;

    dist2 := FLOAT32_INFINITY;
    for entity, entity_index : app.entities {
        if entity.is_visible {
            if entity.mesh.positions.count <= app.user_selection_max_point_count_for_selectable_entity {
                for vertex, vertex_index : entity.mesh.positions {
                    p := (entity.mesh.world_from_model * make_vector4(vertex, 1.)).xyz;
                    c, d2, t := distance_point3_ray3(p, ray);
                    if d2 < dist2 {
                        dist2 = d2;
                        result.vertex_position = p;
                        result.vertex_index = vertex_index;
                        result.entity_index = entity_index;
                    }
                }

                if result.vertex_index != -1 for clip : entity.display_info.clip_ranges if clip.is_active {
                    plane := make_hyperplane3(clip.normal, Vector3.{0, 0, 0});
                    dist := signed_distance_point3_plane3(result.vertex_position, plane);
                    if (dist <= clip.min || dist >= clip.max) {
                        ini :: initializer_of(type_of(result));
                        ini(*result);
                    }
                }
            }
        }
    }


    return result;
}

replace_entity :: (old : *Entity, old_index : s64, new : *Entity) {
    if new {
        // Maintain the following information after the entity reload
        new.is_visible            = old.is_visible;
        new.is_selected           = old.is_selected;
        new.display_info          = old.display_info;
        new.generation_index      = old.generation_index;
        new.mesh.world_from_model = old.mesh.world_from_model;

        deinit(old);

        app.entities[old_index] = new;
    }
}

reload_entities :: () {
    for app.entities if it.is_selected {
        entity := load_entity_from_file(it.fully_pathed_filename);
        replace_entity(it, it_index, entity);
    }
}

test_load_entity_from_file :: () {
    print("Running 'test_load_entity_from_file'...");

    success : bool;
    objfile : File;

    test_filename := "__garage_testing.obj";
    objfile, success =  file_open(test_filename, for_writing=true, keep_existing_content=false);
    assert(success);

    TEST1 :: #string DONE
v 10 10 10
v 20 10 10
l 1 2
DONE;
    success = file_write(*objfile, TEST1);
    assert(success);

    entity : *Entity;
    entity = load_entity_from_file(test_filename);
    assert(entity != null);
    assert(entity.type == .POLYLINE_SOUP2);

    print("PASSED\n");
}