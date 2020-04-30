#import "Basic";

main :: () {
    strings : [3]string;

    // This works using braces... 
    for *strings {
        <<it = sprint("%", it_index);
    }

    for *strings print("[%] %\n", it_index, <<it);

    // ...but breaks without them
    // for *strings <<it = sprint("%", it_index); // "Error: Operator '=' can only be used at statement level."
}

#run main();