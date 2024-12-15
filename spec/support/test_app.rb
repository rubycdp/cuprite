# frozen_string_literal: true

require "capybara/spec/test_app"

class TestApp
  configure do
    set :protection, except: :frame_options
  end
  CUPRITE_VIEWS  = "#{File.dirname(__FILE__)}/views"
  CUPRITE_PUBLIC = "#{File.dirname(__FILE__)}/public"

  set :erb, layout: File.read("#{CUPRITE_VIEWS}/layout.erb")

  helpers do
    def requires_credentials(login, password)
      return if authorized?(login, password)

      headers["WWW-Authenticate"] = %(Basic realm="Restricted Area")
      halt 401, "Not authorized\n"
    end

    def authorized?(login, password)
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && (@auth.credentials == [login, password])
    end
  end

  get "/cuprite/test.js" do
    content_type :js
    File.read("#{CUPRITE_PUBLIC}/test.js")
  end

  get "/cuprite/jquery.min.js" do
    content_type :js
    File.read("#{CUPRITE_PUBLIC}/jquery-3.7.1.min.js")
  end

  get "/cuprite/jquery-ui.min.js" do
    content_type :js
    File.read("#{CUPRITE_PUBLIC}/jquery-ui-1.13.2.min.js")
  end

  get "/cuprite/unexist.png" do
    halt 404
  end

  get "/cuprite/status/:status" do
    status params["status"]
    render_view "with_different_resources"
  end

  get "/cuprite/redirect_to_headers" do
    redirect "/cuprite/headers"
  end

  get "/cuprite/redirect" do
    redirect "/cuprite/with_different_resources"
  end

  get "/cuprite/get_cookie" do
    request.cookies["capybara"]
  end

  get "/cuprite/show_cookies" do
    render_view "show_cookies"
  end

  get "/cuprite/set_cookie_slow" do
    sleep 1
    cookie_value = "test_cookie"
    response.set_cookie("stealth", cookie_value)
    render_string("Cookie set to #{cookie_value}")
  end

  get "/cuprite/slow" do
    sleep 0.2
    render_string("slow page")
  end

  get "/cuprite/really_slow" do
    sleep 3
    render_string("really slow page")
  end

  get "/cuprite/basic_auth" do
    requires_credentials("login", "pass")
    render_view :basic_auth
  end

  post "/cuprite/post_basic_auth" do
    requires_credentials("login", "pass")
    render_string("Authorized POST request")
  end

  get "/cuprite/cacheable" do
    cache_control :public, max_age: 60
    etag "deadbeef"
    render_string("Cacheable request <a href='/cuprite/cacheable'>click me</a>")
  end

  get "/cuprite/:view" do |view|
    render_view view
  end

  get "/cuprite/arbitrary_path/:status/:remaining_path" do
    status params["status"].to_i
    params["remaining_path"]
  end

  protected

  def render_view(view)
    erb File.read("#{CUPRITE_VIEWS}/#{view}.erb")
  end

  def render_string(str)
    erb str
  end
end
