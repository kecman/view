/*
namespace fem {

struct Node {
    // int id; // implicit in container
    num::vec3 position;
    num::tvec3 displacement;

    // Boundary conditions
    num::vec3 fixed;
    num::vec3 force;
};

// tetrahedron
struct Element {
    struct ShapeFunction {
        std::array<float, 4> value;
        std::array<float, 4> gradient;
    };

    ShapeFunction shape_function(num::vec3 local);
    num::vec3 geometry(num::vec3 local);

    std::array<int, 4> nodes;
};

struct Mesh {
    std::vector<Node> nodes;
    std::vector<Element> elements;
};

struct Quadrature {

    struct IntegrationPoint {
        float weight;
        num::vec3 point;
    };

    static std::array<IntegrationPoint> rule = {
        // const double a = 0.13819660112501051518; // (5-sqrt(5))/20
        // const double b = 0.58541019662496845446; // 1 - 3*a
        // const double w = 0.04166666666666666667; // (1/4)*(1/6)
        // ublas::bounded_vector<double,3> p;
        // p(0) = a; p(1) = a; p(2) = a; weightsAndPoints[ 0 ] = std::make_pair( w, p );
        // p(0) = b; p(1) = a; p(2) = a; weightsAndPoints[ 1 ] = std::make_pair( w, p );
        // p(0) = a; p(1) = b; p(2) = a; weightsAndPoints[ 2 ] = std::make_pair( w, p );
        // p(0) = a; p(1) = a; p(2) = b; weightsAndPoints[ 3 ] = std::make_pair( w, p );
    };
};

// test shape functions (evaluate and gradients)

// compute_element_matrix
// compute_element_rhs
// assemble_element_matrix
// assemble_element_rhs
// solve_system
// apply_solution
// log_vtu


} // namespace fem
*/