describe("opentracing.span_context", function()
	local opentracing_span_context = require "opentracing.span_context"
	local new_context = opentracing_span_context.new
	it("has working .is function", function()
		assert.falsy(opentracing_span_context.is(nil))
		assert.falsy(opentracing_span_context.is({}))
		local context = new_context()
		assert.truthy(opentracing_span_context.is(context))
	end)
	it("doesn't allow constructing with invalid trace id", function()
		assert.has.errors(function()
			new_context({})
		end)
	end)
	it("doesn't allow constructing with invalid span id", function()
		assert.has.errors(function()
			new_context(nil, {})
		end)
	end)
	it("doesn't allow constructing with invalid parent id", function()
		assert.has.errors(function()
			new_context(nil, nil, {})
		end)
	end)
	it("allows constructing with baggage items", function()
		local baggage_arg = {
			foo = "bar";
			somekey = "some value";
		}
		local context = new_context(nil, nil, nil, nil, baggage_arg)
		assert.same("bar", context:get_baggage("foo"))
		assert.same("some value", context:get_baggage("somekey"))
		baggage_arg.modified = "other"
		assert.same(nil, context:get_baggage("modified"))
	end)
end)
