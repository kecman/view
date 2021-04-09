Entity :: struct {
    Entity_Type :: enum {
        UNKNOWN;
        POLYLINE_SOUP2;
        POLYLINE_SOUP3;
        POLYGON_SOUP;
        MESH;
    }
    type : Entity_Type = .UNKNOWN;

    // Consider making a Display_Mesh type
    display_info : Display_Info;
    mesh : Mesh;

    // @TODO move mesh into here
    // @TODO add mesh bounding box here

    fully_pathed_filename : string;
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
        case .POLYLINE_SOUP2; {
            entity := cast(*Polyline_Soup2_Entity)base;
            deinit(*entity.mesh);
            deinit(*entity.shape);
        }
        case .POLYLINE_SOUP3; {
            entity := cast(*Polyline_Soup3_Entity)base;
            deinit(*entity.mesh);
            deinit(*entity.shape);
        }
        case .POLYGON_SOUP; {
            entity := cast(*Polygon_Soup_Entity)base;
            deinit(*entity.mesh);
            deinit(*entity.shape);
        }
        case .MESH; {
            entity := cast(*Mesh_Entity)base;
            deinit(*entity.mesh);
        }
        case .UNKNOWN;
    }

    if base.display_info.vbo glDeleteBuffers(1, *base.display_info.vbo);
    if base.display_info.ibo glDeleteBuffers(1, *base.display_info.ibo);
    base.display_info.vbo = 0;
    base.display_info.ibo = 0;
    base.display_info.is_dirty = true;

    free(base.fully_pathed_filename.data);
}

get_mesh :: (base : *Entity) -> *Mesh {
    if #complete base.type == {
        case .POLYLINE_SOUP2; #through;
        case .POLYLINE_SOUP3; #through;
        case .POLYGON_SOUP;   #through;
        case .MESH; {
            return *base.mesh;
        }
        case .UNKNOWN; {
            return null;
        }
    }
}

load_entity_from_file :: (filename : string) -> *Entity
{
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

        hash := get_hash(`entity.fully_pathed_filename);
        `entity.display_info.color.x = cast(float)(hash % 257) / 256;
        `entity.display_info.color.y = cast(float)(get_hash(hash) % 257) / 256;
        `entity.display_info.color.z = cast(float)(get_hash(get_hash(hash)) % 257) / 256;

        buffer_mesh(*`entity.mesh, *`entity.display_info);

        log("Inferred entity type '%'", `entity.type);
    }

    if #complete mesh.geometry_format == {
        case .LINES;

            bbox := bounding_box(mesh);
            if diagonal(bbox).z == 0 {
                shape, ok := to_Polyline_Soup2(mesh);
                assert(ok);

                entity := New(Polyline_Soup2_Entity);
                entity.shape = shape;
                Common_Init();
                return entity;
            } else {
                shape, ok := to_Polyline_Soup3(mesh);
                assert(ok);

                entity := New(Polyline_Soup3_Entity);
                entity.shape = shape;
                Common_Init();
                return entity;
            }

        case .TRIANGLES;

            entity := New(Mesh_Entity);
            Common_Init();
            return entity;

        case .POINTS;

            entity := New(Mesh_Entity);
            Common_Init();
            return entity;

        case .UNKNOWN; #through;
        case;

            log("Skipped (unsupported geometry type %)\n", mesh.geometry_format);
            deinit(*mesh);
            return null;
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