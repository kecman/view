#import "Basic";
Log :: #import "Log";

main :: () {
    print("Start testing\n");
    print("\" test 1: %1 success \"\n", "A", "B");
    print("\" test 2: %2 success \"\n", "A", "B");
    print("\" test 3: %0 success \"\n", "A", "B");
    print("Done testing\n"); 
}

#run main();