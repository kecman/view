Entity :: struct {
    Entity_Type :: enum {
        UNKNOWN;
        POLYLINE_SOUP2;
        POLYLINE_SOUP3;
        POLYGON_SOUP;
        MESH;
    }
    type : Entity_Type = .UNKNOWN;

    visible : bool = true;
    visible_sweep_hovered : bool = false;
    flash_hovered : bool = false;
    flash_wave_dt : float = 0.;

    // @TODO add bounding box

}

Polyline_Soup2_Entity :: struct {
    using base : Entity;
    type = .POLYLINE_SOUP2;

    shape : geom.Polyline_Soup2;
    mesh : Mesh; // for rendering
}

Polyline_Soup3_Entity :: struct {
    using base : Entity;
    type = .POLYLINE_SOUP3;

    shape : geom.Polyline_Soup3;
    mesh : Mesh; // for rendering
}


Polygon_Soup_Entity :: struct {
    using base : Entity;
    type = .POLYGON_SOUP;

    shape : geom.Polygon_Soup;
    mesh : Mesh; // for rendering
}

Mesh_Entity :: struct {
    using base : Entity;
    type = .MESH;

    mesh : Mesh;
}

deinit :: (base : *Entity) {
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
}

get_mesh :: (base : *Entity) -> *Mesh {
    if #complete base.type == {
        case .POLYLINE_SOUP2; {
            entity := cast(*Polyline_Soup2_Entity)base;
            return *entity.mesh;
        }
        case .POLYLINE_SOUP3; {
            entity := cast(*Polyline_Soup3_Entity)base;
            return *entity.mesh;
        }
        case .POLYGON_SOUP; {
            entity := cast(*Polygon_Soup_Entity)base;
            return *entity.mesh;
        }
        case .MESH; {
            entity := cast(*Mesh_Entity)base;
            return *entity.mesh;
        }
        case .UNKNOWN; {
            return null;
        }
    }
}

should_load_entity_from_file :: (filename : string) -> bool
{
    skip := false;
    for app.entities {
        mesh := get_mesh(it);
        if mesh && mesh.fully_pathed_filename == filename {
            skip = true;
            break;
        }
    }
    if skip {
        log("Skipped file: '%' (already loaded)\n", filename);
    }
    return !skip;
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

    if #complete mesh.geometry_format == {
        case .LINES;

            bbox := geom.bounding_box(mesh);
            if diagonal(bbox).z == 0 {
                shape, ok := to_Polyline_Soup2(mesh);
                assert(ok);

                entity := New(Polyline_Soup2_Entity);
                entity.mesh = mesh;
                entity.shape = shape;

                log("Inferred 2D polyline soup");
                return entity;
            } else {
                shape, ok := to_Polyline_Soup3(mesh);
                assert(ok);

                entity := New(Polyline_Soup3_Entity);
                entity.mesh = mesh;
                entity.shape = shape;

                log("Inferred 3D polyline soup");
                return entity;
            }

        case .TRIANGLES;

            entity := New(Mesh_Entity);
            entity.mesh = mesh;

            log("Inferred triangle mesh");
            return entity;

        case .POINTS;

            entity := New(Mesh_Entity);
            entity.mesh = mesh;

            log("Inferred point cloud");
            return entity;

        case .UNKNOWN; #through;
        case;

            log("Skipped (unsupported geometry type %)\n", mesh.geometry_format);
            deinit(*mesh);
            return null;
    }
}
