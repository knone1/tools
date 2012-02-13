adb shell "cd /sys/kernel/debug/tracing;
	echo 0 > tracing_enabled; 
	echo 0 > tracing_on;
	echo funcgraph-duration >trace_options
	echo 30000 > buffer_size_kb 
	echo function_graph > ./current_tracer;
	echo 0 > ./trace;
	echo 1 > ./tracing_enabled"

