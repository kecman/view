#import "Basic";
#import "Compiler";

AxisBox :: struct (T : Type, N : int)
#modify {
    info := cast(*Type_Info) T;
    if info.type != Type_Info_Tag.FLOAT || info.type != Type_Info_Tag.INTEGER {
        compiler_report_error(#file, #line, 0, "Type passed to AxisBox is not a number!");
    }
}
{
    min : [N]T = ---;
    max : [N]T = ---;
};

main :: () {
    AxisBox2f :: AxisBox(float, 2);
    bbox : AxisBox2f;
    print("%\n", bbox);
}