package = "opentracing"
version = "0.0.2-0"

source = {
	url = "https://github.com/kong/opentracing-lua/archive/v0.0.2.zip";
	dir = "opentracing-lua-0.0.2";
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
		["opentracing"] = "opentracing/init.lua";
		["opentracing.span"] = "opentracing/span.lua";
		["opentracing.span_context"] = "opentracing/span_context.lua";
		["opentracing.tracer"] = "opentracing/tracer.lua";
	};
}
