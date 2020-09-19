entities : [..]*Entity;

Entity :: struct {
    Entity_Type :: enum {
        UNKNOWN;
        POLYLINE_SOUP2;
        POLYGON_SOUP2;
        MESH;
        FLOAT;
    }
    type : Entity_Type = .UNKNOWN;

    id : string;
}

Polyline_Soup2_Entity :: struct {
    using base : Entity;
    shape : geom.Polyline_Soup2;
    mesh : Mesh; // for rendering
}

Polygon_Soup2_Entity :: struct {
    using base : Entity;
    shape : geom.Polygon_Soup2;
    mesh : Mesh; // for rendering
}

Mesh_Entity :: struct {
    using base : Entity;
    mesh : Mesh;
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