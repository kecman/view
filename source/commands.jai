Command_Info :: struct {
    name : string;
    procedure : ([] string) -> void;
}

command_list : [..]Command_Info;

init_commands :: () {
    info : Command_Info;
    info.name = "offset";
    info.procedure = tmp_offset;

    array_add(*command_list, info);
}

#scope_file

tmp_offset :: (args : []string) {
    console_add_log("[error] offset not implemented");
}