// Compile with:
//
// $ gcc -shared -o libmyfuncs.so myfuncs.c # create dll libmyfuncs.so
// $ nm -D libmyfuncs.so # inspect exported symbols in the dll (captital T indicates add_func is exported and in the .text section)
// $ objdump -T libmyfuncs.so # see also this command, you can see add_func is in the .text section
//
// The run sandbox_004_clibs.jai
// Note: I got stuck at one point because I had a static library with the same name prefix as the dynamic one, and got ldd error when running hte jai compiler

// Tasks
//
// Read Bryant, O'Hallaron Chapter 7 to learn more about linking

int add_func(int a, int b) { return a + b; }