# frozen_string_literal: true

require "capybara/spec/test_app"

class TestApp
  configure do
    set :protection, except: :frame_options
  end
  CUPRITE_VIEWS  = "#{File.dirname(__FILE__)}/views".freeze
  CUPRITE_PUBLIC = "#{File.dirname(__FILE__)}/public".freeze

  set :erb, layout: File.read("#{CUPRITE_VIEWS}/layout.erb")

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

  get "/cuprite/redirect" do
    redirect "/cuprite/with_different_resources"
  end

  get "/cuprite/get_cookie" do
    request.cookies["capybara"]
  end

  get "/cuprite/slow" do
    sleep 0.2
    render_string("slow page")
  end

  get "/cuprite/really_slow" do
    sleep 3
    render_string("really slow page")
  end

  get "/cuprite/attachment.txt" do
    attachment "attachment.txt"
    "attachment contents"
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
