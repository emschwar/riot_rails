class Riot::Assertion
  # Asserts that the body of the response equals or matches the expected expression. Expects actual to
  # be the controller.
  #
  #   controller.renders("a bunch of html")
  #   controller.renders(/bunch of/)
  assertion(:renders) do |actual, expected|
    actual_body = actual.response.body
    if (expected.kind_of?(Regexp) ? (actual_body =~ expected) : (expected == actual_body))
      pass
    else
      verb = expected.kind_of?(Regexp) ? "match" : "equal"
      fail("expected response body #{actual_body.inspect} to #{verb} #{expected.inspect}")
    end
  end

  # Asserts that the name you provide is the basename of the rendered template. For instance, if you
  # expect the rendered template is named "foo_bar.html.haml" and you pass "foo_bar" into
  # renders_template, the assertion would pass. If instead you pass "foo" into renders_template, the
  # assertion will fail. Using Rails' assert_template both assertions would pass
  #
  #   controlling :things
  #   controller.renders_template(:index)
  #   controller.renders_template("index")
  #   controller.renders_template("index.erb") # fails even if that's the name of the template
  assertion(:renders_template) do |actual, expected_name|
    name = expected_name.to_s
    actual_template_path = actual.response.rendered[:template].to_s
    actual_template_name = File.basename(actual_template_path)
    msg = "expected template #{name.inspect}, not #{actual_template_path.inspect}"
    actual_template_name.to_s.match(/^#{name}(\.\w+)*$/) ? pass : fail(msg)
  end

  # Asserts that the HTTP response code equals your expectation. You can use the symbolized form of the
  # status code or the integer code itself. Not currently supporting status ranges; such as: +:success+,
  # +:redirect+, etc.
  #
  #   controller.response_code(:ok)
  #   controller.response_code(200)
  #   
  #   controller.response_code(:not_found)
  #   controller.response_code(404)
  #   
  #   # A redirect
  #   controller.response_code(:found)
  #   controller.response_code(302)
  #
  # See +ActionController::StatusCodes+ for the list of available codes.
  assertion(:response_code) do |actual, expected_code|
    if expected_code.kind_of?(Symbol)
      expected_code = ::ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE[expected_code]
    end
    actual_code = actual.response.response_code
    expected_code == actual_code ? pass : fail("expected response code #{expected_code}, not #{actual_code}")
  end

  # Asserts that the response from an action is a redirect and that the path or URL matches your
  # expectations. If the response code is not in the 300s, the assertion will fail. If the reponse code
  # is fine, but the redirect-to path or URL do not exactly match your expectation, the assertion will
  # fail.
  #
  # +redirected_to+ expects you to provide your expected path in a lambda. This is so you can use named
  # routes, which are - as it turns out - handy. It's also what I would expect to be able to do. Using
  # lambdas is not ideal, so if you're smart, solve this problem :)
  #
  #   controlling :people
  #   setup do
  #     post :create, :person { ... }
  #   end
  #
  #   controller.redirected_to( lambda { person_path(...) } )
  #
  # PS: There is a difference between saying +named_route_path+ and +named_route_url+ and Riot Rails will
  # be very strict (read: annoying) about it :)
  assertion(:redirected_to) do |actual, *expectings|
    expectation_block = expectings.last
    actual_response_code = actual.response.response_code
    if (300...400).member?(actual_response_code)
      expected_redirect = actual.url_for(actual.instance_eval(&expectation_block)) # need to execute in situation somehow
      actual_redirect = actual.url_for(actual.response.redirected_to)
      msg = "expected to redirect to <#{expected_redirect}>, not <#{actual_redirect}>"
      expected_redirect == actual_redirect ? pass : fail(msg)
    else
      fail("expected response to be a redirect, but was #{actual_response_code}")
    end
  end

end # Riot::Assertion
