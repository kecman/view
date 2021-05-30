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

entity_filename_with_generation_index :: (using entity : Entity) -> string {
    text : string;

    name := fully_pathed_filename;
    path := parse_path(fully_pathed_filename);
    if path.words.count {
        name = path.words[path.words.count - 1];
    }

    if generation_index == 0 {
        text = tprint("%", name);
    } else {
        text = tprint("% <%>", name, generation_index);
    }
    return text;
}

entity_fully_pathed_filename_with_generation_index :: (using entity : Entity) -> string {
    text : string;
    if generation_index == 0 {
        text = tprint("%", fully_pathed_filename);
    } else {
        text = tprint("% <%>", fully_pathed_filename, generation_index);
    }
    return text;
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
    ray.origin = (transform * make_vector4(to_ndc(io().MousePos), -1., 1.)).xyz;
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
            }
        }
    }

    return result;
}

replace_entity :: (old : *Entity, old_index : s64, new : *Entity) {
    if new {
        // Maintain the following information after the entity reload
        new.display_info = old.display_info;
        new.generation_index = old.generation_index;
        new.is_selected = old.is_selected;
        new.mesh.world_from_model = old.mesh.world_from_model;

        deinit(old);

        app.entities[old_index] = new;
    }
}

// Reload the selected entities or the hovered entity if none are selected
reload_entities :: () {
    count := 0;
    for app.entities if it.is_selected {
        entity := load_entity_from_file(it.fully_pathed_filename);
        replace_entity(it, it_index, entity);
        count += 1;
    }

    if count == 0 {
        for app.entities if it.is_hovered {
            entity := load_entity_from_file(it.fully_pathed_filename);
            replace_entity(it, it_index, entity);
            count += 1;
        }
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