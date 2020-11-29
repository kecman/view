entities : [..]*Entity; // @Cleanup: Why bother with pointers here??

Entity :: struct {
    Entity_Type :: enum {
        UNKNOWN;
        POLYLINE_SOUP2;
        POLYGON_SOUP2;
        MESH;
        FLOAT;
    }
    type : Entity_Type = .UNKNOWN;
}

Polyline_Soup2_Entity :: struct {
    using base : Entity;
    type = .POLYLINE_SOUP2;

    shape : geom.Polyline_Soup2;
    mesh : Mesh; // for rendering
}


Polygon_Soup2_Entity :: struct {
    using base : Entity;
    type = .POLYGON_SOUP2;

    shape : geom.Polygon_Soup2;
    mesh : Mesh; // for rendering
}

Mesh_Entity :: struct {
    using base : Entity;
    type = .MESH;

    mesh : Mesh;
}

deinit_entity :: (base : *Entity) {
    if #complete base.type == {
        case .POLYLINE_SOUP2; {
            entity := cast(*Polyline_Soup2_Entity)base;
            deinit_mesh(*entity.mesh);
            polyline_soup_free_and_reset(*entity.shape); // deinit_polyline_soup2(*entity.shape);
        }
        case .POLYGON_SOUP2; {
            entity := cast(*Polygon_Soup2_Entity)base;
            deinit_mesh(*entity.mesh);
            polygon_soup_free_and_reset(*entity.shape); // deinit_polygon_soup2(*entity.shape);
        }
        case .MESH; {
            entity := cast(*Mesh_Entity)base;
            deinit_mesh(*entity.mesh);
        }
        case .UNKNOWN;
        case .FLOAT;
    }
}

get_mesh :: (base : *Entity) -> *Mesh {
    if #complete base.type == {
        case .POLYLINE_SOUP2; {
            entity := cast(*Polyline_Soup2_Entity)base;
            return *entity.mesh;
        }
        case .POLYGON_SOUP2; {
            entity := cast(*Polygon_Soup2_Entity)base;
            return *entity.mesh;
        }
        case .MESH; {
            entity := cast(*Mesh_Entity)base;
            return *entity.mesh;
        }
        case .UNKNOWN; {
            return null;
        }
        case .FLOAT; {
            return null;
        }
    }
}