require "test_helper"
require "uri"

class SwitcherUrlsTest < ActionDispatch::IntegrationTest
  test "switcher treats URL options as query data and preserves nested filters" do
    query = {
      "host" => "attacker.example", "protocol" => "https", "script_name" => "/unexpected",
      "page" => "2", "filters" => { "tags" => [ "design", "review" ] }
    }

    get posts_path, params: query.merge("vv" => "v2")

    assert_switcher_urls("/posts", query)
  end

  test "switcher preserves mounted paths and replaces configured parameter names" do
    original_param = ActionVersionPreview.param_name
    [ :version, "version" ].each do |param_name|
      ActionVersionPreview.param_name = param_name
      get "/sandbox/posts", params: { version: "v2" }, env: { "SCRIPT_NAME" => "/sandbox", "PATH_INFO" => "/posts" }

      assert_switcher_urls("/sandbox/posts", {}, "version")
    end
  ensure
    ActionVersionPreview.param_name = original_param
  end

  test "switcher does not include POST body fields in navigation links" do
    post "/posts?vv=v2&page=2", params: { draft: { private_note: "not for a URL" }, authenticity_token: "body-token" }

    assert_switcher_urls("/posts", { "page" => "2" })
  end

  private

  def assert_switcher_urls(path, query, param_name = "vv")
    assert_response :success
    links = Nokogiri::HTML(response.body).css("a")
    assert_equal [ "Default", "REDESIGN", "V2" ], links.map(&:text)

    links.zip([ nil, "redesign", "v2" ]).each do |link, variant|
      uri = URI.parse(link["href"])
      assert_equal path, uri.path
      assert_nil uri.host
      assert_nil uri.scheme
      expected_query = variant ? query.merge(param_name => variant) : query
      assert_equal expected_query, Rack::Utils.parse_nested_query(uri.query)
    end
  end
end
