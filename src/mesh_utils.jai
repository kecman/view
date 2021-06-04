
to_Mesh :: (shape : Polyline_Soup2) -> Mesh, bool #must {
    mesh : Mesh;

    if is_empty(shape) {
        return mesh, false;
    }

    mesh.geometry_format = .LINES;

    index_offset := 0;
    for polyline : shape.polylines {
        if is_empty(polyline) {
            continue;
        }

        point := polyline.points[0];
        array_add(*mesh.positions, make_vector3(point.x, point.y, 0));

        for edge_index : 0..polyline.points.count-2 {
            point = polyline.points[edge_index + 1];
            array_add(*mesh.positions, make_vector3(point.x, point.y, 0));
            array_add(*mesh.indices, xx (index_offset + edge_index));
            array_add(*mesh.indices, xx (index_offset + edge_index  + 1));
        }

        index_offset += polyline.points.count;
    }

    return mesh, true;
}

to_Polyline_Soup2 :: #bake_arguments to_Polyline_Soup(Point = Vector2);
to_Polyline_Soup3 :: #bake_arguments to_Polyline_Soup(Point = Vector3);

to_Polyline_Soup :: (mesh : Mesh, Point : $Type) -> Polyline_Soup(Point), bool #must {
    result : Polyline_Soup(Point);

    if mesh.geometry_format != .LINES || mesh.indices.count < 2 || mesh.positions.count == 0 {
        return result, false;
    }

    get_edge :: (mesh : Mesh, edge_index : int) -> Indexed_Edge3 {
        assert(2 * edge_index + 1 < mesh.indices.count);

        edge : Indexed_Edge3;
        edge.from_index = mesh.indices[2 * edge_index];
        edge.to_index   = mesh.indices[2 * edge_index + 1];
        edge.from_point = *mesh.positions[edge.from_index];
        edge.to_point   = *mesh.positions[edge.to_index];

        return edge;
    }

    get_point :: inline (point : Vector3) -> Point {
        #if Point == Vector2 {
            return point.xy;
        } else {
            return point;
        }
    }

    edge_count := mesh.indices.count / 2;

    edge_index := 0;
    edge := get_edge(mesh, edge_index);

    // Start a new polyline
    polyline := array_add(*result.polylines);
    array_add(*polyline.points, get_point(<<edge.from_point));

    while true {
        prev_edge := edge;

        // Get next edge
        edge_index += 1;
        if edge_index >= edge_count {
            break;
        }

        edge = get_edge(mesh, edge_index);

        if edge.from_index == prev_edge.to_index {
            // Add to current polyline
            array_add(*polyline.points, get_point(<<edge.from_point));
        } else if edge_index != edge_count {
            // End current polyline
            array_add(*polyline.points, get_point(<<prev_edge.to_point));

            // Start a new polyline
            polyline = array_add(*result.polylines);
            array_add(*polyline.points, get_point(<<edge.from_point));
        }
    }

    // Terminate current polyline
    array_add(*polyline.points, get_point(<<edge.to_point));

    return result, true;
}

to_Mesh :: (shape : Polygon_Soup) -> Mesh, bool #must {
    result : Mesh;

    if shape.polygons.count == 0 {
        return result, false;
    }

#if ENABLE_BOOST_POLYGON {
    #import "BoostPolygon"; // for convex_decomposition
    convex : Polygon_Soup = BoostPolygon.convex_decomposition(*shape);

    for convex.polygons {
        if it.inner_rings.count != 0 {
            return result, false;
        }
    }

    result.geometry_format = .TRIANGLES;

    mesh_index := 0;
    for convex.polygons {
        i := 0;
        j := 1;
        k := 2;
        while k < it.outer_ring.points.count {
            pi := it.outer_ring.points[i];
            pj := it.outer_ring.points[j];
            pk := it.outer_ring.points[k];
            array_add(*result.positions, make_vector3(pi.x, pi.y, 0));
            array_add(*result.positions, make_vector3(pj.x, pj.y, 0));
            array_add(*result.positions, make_vector3(pk.x, pk.y, 0));
            array_add(*result.indices, xx (mesh_index + 0));
            array_add(*result.indices, xx (mesh_index + 1));
            array_add(*result.indices, xx (mesh_index + 2));
            j += 1;
            k += 1;
            mesh_index += 3;
        }
    }

    return result, true;
} else {
    return result, false;
}
}

// @TODO only really needed to load polygon objs, but we should just do that with wkt files instead
to_Polygon_Soup :: (mesh : Mesh) -> Polygon_Soup, bool #must {
    result : Polygon_Soup;
    // make each triangle into a polygon
    // boolean union triangles? (this should be a parameter)
    // not very nice at all but I guess it works
    return result, false;
}

to_Mesh :: (m : par_shapes_mesh) -> Mesh
{
    using result : Mesh;

    geometry_format = .TRIANGLES;
    array_copy(*positions, m.points);
    array_copy(*normals, m.normals);

    array_reserve(*indices, m.triangles.count * 3);
    memcpy(indices.data, m.triangles.data, m.triangles.count * size_of(m.Triangle));
    indices.count = m.triangles.count * 3;

    // @Incomplete tcoords

    return result;
}

