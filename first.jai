#run {
    #import "Basic";
    #import "Codex";
    #import "Compiler";

    set_build_options_dc(.{do_output = false});

    w := compiler_create_workspace("Target");
    options := get_build_options(w);
    copy_commonly_propagated_fields(get_build_options(), *options);
    options.output_executable_name = "negative-zero";
    set_build_options(options, w);

    compiler_begin_intercept(w);
    add_build_file("src/main.jai", w);

    while true {
        message := compiler_wait_for_message();
        if message.kind == {
        case .TYPECHECKED;
            // Right now this prints EVERY proc and how many times it's called in the binary, looking for a way to restrict it to just `#loaded` procs to find procs we don't use
            // tc := cast(*Message_Typechecked)message;
            // for tc.procedure_bodies {
            //     metrics := collect_metrics(it);
            //     header := it.expression.header;
            //     print("% -> %\n", header.name, metrics.total_calls);
            // }
        case .COMPLETE;
            mc := cast(*Message_Complete)message;
            if mc.error_code != .NONE {
                exit(1);
            }
            break;
        }
    }
    compiler_end_intercept(w);
    print("\n");
}
