#import "Basic";
#load "input.jai";

main :: () {

    Foo :: struct {
        f : float;
    }

    Baz :: Bar;
    Bar :: struct {
        f : float;
    }

    print("      %\n", <<type_info(Foo));
    print("      %\n", <<type_info(Bar));
    print("      %\n", <<type_info(Baz));

    print("***** %\n", Foo == Bar);
    print("***** %\n", Baz == Bar);

    generate_cpp(type_info(Foo));
}

indent :: (depth : int) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);
    for 0..depth-1 append(*builder, "    ");
    return builder_to_string(*builder); 
}

generate_cpp :: (info : *Type_Info_Struct, depth : int = 0) {
    assert(info.type == Type_Info_Tag.STRUCT);

    print("%struct % {\n", indent(depth), info.name);
    for * info.members {
        generate_cpp(it, depth + 1);
    }
    print("%};\n", indent(depth));
}

generate_cpp :: (info : *Type_Info_Struct_Member, depth : int = 0) {
    using Type_Info_Tag;

    if info.type.type == {

        case INTEGER;

            print("%", indent(depth));
            info_int := cast(*Type_Info_Integer) info.type;
            if info_int.runtime_size == {
                case 1; if info_int.signed print("int8_t");  else print("uint8_t");
                case 2; if info_int.signed print("int16_t"); else print("uint16_t");
                case 4; if info_int.signed print("int32_t"); else print("uint32_t");
                case 8; if info_int.signed print("int64_t"); else print("uint64_t");
                case; assert(false);
            }
            print(" %;\n", info.name);

        case FLOAT;

            print("%", indent(depth));
            info_float := cast(*Type_Info_Float) info.type;
            if info_float.runtime_size ==  {
                case 4; print("float");
                case 8; print("double");
                case; assert(false);
            }
            print(" %;\n", info.name);

        case ENUM;

            info_enum := cast(*Type_Info_Enum) info.type;
            print("%enum class % : ", indent(depth), info_enum.name);
            if info_enum.internal_type.runtime_size == {
                case 1; if info_enum.internal_type.signed print("int8_t");  else print("uint8_t");
                case 2; if info_enum.internal_type.signed print("int16_t"); else print("uint16_t");
                case 4; if info_enum.internal_type.signed print("int32_t"); else print("uint32_t");
                case 8; if info_enum.internal_type.signed print("int64_t"); else print("uint64_t");
                case; assert(false);
            }
            print(" {");
            for info_enum.names print(" %,", it);
            print(" };\n");
            print("%", indent(depth));
            print("% %;\n", info_enum.name, info.name);

        case STRUCT;

            info_struct := cast(*Type_Info_Struct) info.type;
            generate_cpp(info_struct, depth); // recurse
            print("%", indent(depth));
            print("% %;\n", info_struct.name, info.name);

        // case PROCEDURE; // @Question How to get procedure name from type?
        // case ARRAY; // @Question How to get array name from type?
        // case BOOL;
        // case STRING;
        // case TYPE;
        // case POINTER;
        // case VOID;
        // case OVERLOAD_SET;
        // case ANY;
        // case POLYMORPHIC_VARIABLE;
        // case CODE;
    }
}
