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
    hovered : bool = false;
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