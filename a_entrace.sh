adb shell "cd /sys/kernel/debug/tracing;
	echo start;
	echo 0 > tracing_enabled; 
	echo 0 > tracing_on;
	echo funcgraph-abstime > trace_options;
	echo funcgraph-proc > trace_options;
	echo trace_printk > trace_options;
	echo function > current_tracer;
	echo 0 > options/func_stack_trace
	echo 20000 > buffer_size_kb;
	echo 0 > ./trace;
	echo 0 > /sys/kernel/debug/tracing/per_cpu/cpu0/trace;
	echo 1 > ./tracing_enabled;
	cat /sys/kernel/debug/tracing/tracing_enabled;
	cat /sys/kernel/debug/tracing/tracing_on;
	cat /sys/kernel/debug/tracing/buffer_size_kb;
	cat /sys/kernel/debug/tracing/trace_options;
	echo """"
	echo 0 > tracing_on;
	echo done;"

