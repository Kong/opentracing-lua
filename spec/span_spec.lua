describe("opentracing.span", function()
	local tracer = require "opentracing.tracer".new()
	local context = require "opentracing.span_context".new()
	local opentracing_span = require "opentracing.span"
	local new_span = opentracing_span.new
	it("has working .is function", function()
		assert.falsy(opentracing_span.is(nil))
		assert.falsy(opentracing_span.is({}))
		local span = new_span(tracer, context, "foo", 0)
		assert.truthy(opentracing_span.is(span))
		assert.falsy(opentracing_span.is(tracer))
		assert.falsy(opentracing_span.is(context))
	end)
	it("doesn't allow constructing without a tracer", function()
		assert.has.errors(function()
			new_span(nil, context, "foo")
		end)
	end)
	it("doesn't allow constructing without a context", function()
		assert.has.errors(function()
			new_span(tracer, nil, "foo")
		end)
	end)
	it("doesn't allow constructing without a name", function()
		assert.has.errors(function()
			new_span(tracer, context, nil)
		end)
	end)
	it("asks for time from tracer when not passed", function()
		local mock_tracer = mock({
			time = function() return 42 end;
		})
		local span = new_span(mock_tracer, context, "foo", 0)
		span:log("key", "value")
		assert.spy(mock_tracer.time).was.called(1)
		span:finish()
		assert.spy(mock_tracer.time).was.called(2)
	end)
	it("doesn't allow constructing with invalid timestamp", function()
		assert.has.errors(function()
			new_span(tracer, context, "foo", {})
		end)
	end)
	it("can construct with :start_child_span", function()
		local span1 = new_span(tracer, context, "foo", 0)
		local span2 = span1:start_child_span("bar", 1)
		assert.same("foo", span1.name)
		assert.same(0, span1.timestamp)
		assert.same("bar", span2.name)
		assert.same(1, span2.timestamp)
	end)
	it("doesn't allow :finish with invalid timestamp", function()
		local span = new_span(tracer, context, "foo", 0)
		assert.has.errors(function()
			span:finish({})
		end)
	end)
	it("doesn't allow :finish-ing twice", function()
		local span = new_span(tracer, context, "foo", 0)
		span:finish(10)
		assert.has.errors(function()
			span:finish(11)
		end)
	end)
	it("can iterate over empty set of tags", function()
		local span = new_span(tracer, context, "foo", 0)
		for _ in span:each_tag() do
			error("unreachable")
		end
	end)
	it("can :get_tag", function()
		local span = new_span(tracer, context, "foo", 0)
		assert.same(nil, span:get_tag("http.method"))
		span:set_tag("http.method", "GET")
		assert.same("GET", span:get_tag("http.method"))
	end)
	it("can iterate over tags", function()
		local span = new_span(tracer, context, "foo", 0)
		local tags = {
			["http.method"] = "GET";
			["http.url"] = "https://example.com/";
		}
		for k, v in pairs(tags) do
			span:set_tag(k, v)
		end
		local seen = {}
		for k, v in span:each_tag() do
			seen[k] = v
		end
		assert.same(tags, seen)
	end)
	it("can iterate over empty logs collection", function()
		local span = new_span(tracer, context, "foo", 0)
		for _ in span:each_log() do
			error("unreachable")
		end
	end)
	it("can iterate over logs", function()
		local span = new_span(tracer, context, "foo", 0)
		local logs = {
			["thing1"] = 1000; -- valid value **and** valid timestamp
			["thing2"] = 1001;
		}
		for k, v in pairs(logs) do
			local t = v*10
			span:log(k, v, t)
		end
		local seen = {}
		for k, v, t in span:each_log() do
			assert.same(v*10, t)
			seen[k] = v
		end
		assert.same(logs, seen)
	end)
	it("tracks baggage", function()
		local span = new_span(tracer, context, "name", 0)
		-- New span shouldn't have any baggage
		assert.same(nil, span:get_baggage("foo"))
		-- Check normal case
		span:set_baggage("foo", "bar")
		assert.same("bar", span:get_baggage("foo"))
		-- Make sure adding a new key doesn't remove old ones
		span:set_baggage("mykey", "myvalue")
		assert.same("bar", span:get_baggage("foo"))
		assert.same("myvalue", span:get_baggage("mykey"))
		-- Set same key again and make sure it has changed
		span:set_baggage("foo", "other")
		assert.same("other", span:get_baggage("foo"))
	end)
	it("can iterate over baggage", function()
		local span = new_span(tracer, context, "foo", 0)
		local baggage = {
			["baggage1"] = "value1";
			["baggage2"] = "value2";
		}
		for k, v in pairs(baggage) do
			span:set_baggage(k, v)
		end
		local seen = {}
		for k, v in span:each_baggage() do
			seen[k] = v
		end
		assert.same(baggage, seen)
	end)
end)
