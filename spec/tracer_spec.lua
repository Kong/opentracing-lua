describe("opentracing.tracer", function()
	local opentracing_span_context = require "opentracing.span_context"
	local opentracing_tracer = require "opentracing.tracer"
	local new_tracer = opentracing_tracer.new
	it("has working .is function", function()
		assert.falsy(opentracing_tracer.is(nil))
		assert.falsy(opentracing_tracer.is({}))
		local tracer = new_tracer()
		assert.truthy(opentracing_tracer.is(tracer))
	end)
	it("doesn't allow constructing span without a name", function()
		local tracer = new_tracer()
		assert.has.errors(function()
			tracer:start_span(nil)
		end)
	end)
	it("calls sampler for root traces", function()
		local mock_sampler = mock {
			sample = function() return false end;
		}
		local tracer = new_tracer(nil, mock_sampler)
		tracer:start_span("foo")
		assert.spy(mock_sampler.sample).was.called_with(mock_sampler, "foo")
	end)
	it("takes returned sampler tags into account", function()
		local mock_sampler = mock {
			sample = function()
				return true, {
					["sampler.type"] = "mock";
				}
			end;
		}
		local tracer = new_tracer(nil, mock_sampler)
		local span = tracer:start_span("foo")
		assert.spy(mock_sampler.sample).was.called_with(mock_sampler, "foo")
		local tags = {}
		for k, v in span:each_tag() do
			tags[k] = v
		end
		assert.same({["sampler.type"] = "mock";}, tags)
	end)
	it("calls reporter at end of span", function()
		local mock_sampler = mock {
			sample = function() return true end;
		}
		local mock_reporter = mock {
			report = function() end;
		}
		local tracer = new_tracer(mock_reporter, mock_sampler)
		local span = tracer:start_span("foo")
		assert.spy(mock_sampler.sample).was.called_with(mock_sampler, "foo")
		span:finish()
		assert.spy(mock_reporter.report).was.called_with(mock_reporter, span)
	end)
	it("allows passing in tags", function()
		local tracer = new_tracer()
		local tags = {
			["http.method"] = "GET";
			["http.url"] = "https://example.com/";
		}
		local span = tracer:start_span("foo", {
			tags = tags
		})
		local seen = {}
		for k, v in span:each_tag() do
			seen[k] = v
		end
		assert.same(tags, seen)
	end)
	it("allows passing span as a child_of", function()
		local tracer = new_tracer()
		local span1 = tracer:start_span("foo")
		tracer:start_span("bar", {
			child_of = span1
		})
	end)
	it("allows passing span context as a child_of", function()
		local tracer = new_tracer()
		local span1 = tracer:start_span("foo")
		tracer:start_span("bar", {
			child_of = span1.context
		})
	end)
	it("doesn't allow invalid child_of", function()
		local tracer = new_tracer()
		assert.has.errors(function()
			tracer:start_span("foo", {
				child_of = {}
			})
		end)
	end)
	it("doesn't allow invalid references", function()
		local tracer = new_tracer()
		assert.has.errors(function()
			tracer:start_span("foo", {
				references = true
			})
		end)
	end)
	it("works with custom extractor", function()
		local tracer = new_tracer()
		local mock_extractor = spy.new(function()
			local context = opentracing_span_context.new()
			return context
		end)
		tracer:register_extractor("my_type", mock_extractor)
		local carrier = {}
		tracer:extract("my_type", carrier)
		assert.spy(mock_extractor).was.called_with(carrier)
	end)
	it("checks for known extractor", function()
		local tracer = new_tracer()
		assert.has.errors(function()
			tracer:extract("my_unknown_type", {})
		end)
	end)
	it("works with custom injector", function()
		local tracer = new_tracer()
		local mock_injector = stub()
		tracer:register_injector("my_type", mock_injector)

		local span = tracer:start_span("foo")
		local context = span.context
		local carrier = {}
		tracer:inject(context, "my_type", carrier)
		assert.stub(mock_injector).was.called_with(context, carrier)
	end)
	it(":inject takes span", function()
		local tracer = new_tracer()
		local mock_injector = stub()
		tracer:register_injector("my_type", mock_injector)
		local span = tracer:start_span("foo")
		local context = span.context
		local carrier = {}
		tracer:inject(span, "my_type", carrier)
		assert.stub(mock_injector).was.called_with(context, carrier)
	end)
	it("checks for known injector", function()
		local tracer = new_tracer()
		local span = tracer:start_span("foo")
		local context = span.context
		assert.has.errors(function()
			tracer:inject(context, "my_unknown_type", {})
		end)
	end)
end)
