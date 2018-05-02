package = "opentracing"
version = "scm-0"

source = {
	url = "git+https://github.com/kong/opentracing-lua.git";
}

description = {
	summary = "Lua platform API for OpenTracing";
	homepage = "https://github.com/kong/opentracing-lua";
	license = "Apache 2.0";
}

dependencies = {
	"lua >= 5.1";
	"luatz";
	"luaossl";
}

build = {
	type = "builtin";
	modules = {
		["opentracing.span"] = "opentracing/span.lua";
		["opentracing.span_context"] = "opentracing/span_context.lua";
		["opentracing.tracer"] = "opentracing/tracer.lua";
	};
}
