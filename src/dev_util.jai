benchmark_code :: ($name: string, $body: Code) {
    start := current_time_monotonic();
    #insert body;
    end := current_time_monotonic();
    total_ms := to_float64_seconds(end - start) * 1000.0;
    print("%:\ntook %ms to complete!\n", name, total_ms);
}
