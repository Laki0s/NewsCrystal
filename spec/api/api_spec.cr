require "../spec_helper"
require "http/client"
require "json"
require "digest/sha256"

# Drives the Kemal handler chain in-process (no real server), following the
# pattern from Kemal's own test suite.
private def build_main_handler
  Kemal.config.setup
  main_handler = Kemal.config.handlers.first
  current_handler = main_handler
  Kemal.config.handlers.each do |handler|
    current_handler.next = handler
    current_handler = handler
  end
  main_handler
end

private def api_get(path : String) : HTTP::Client::Response
  io = IO::Memory.new
  request = HTTP::Request.new("GET", path)
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  build_main_handler.call(context)
  response.close
  io.rewind
  HTTP::Client::Response.from_io(io, decompress: false)
end

private def article(url : String, source : String, published_at : Time)
  NewsCrystal::Storage::Article.new(
    title: "Title #{url}",
    url: url,
    source: source,
    author: "alice",
    published_at: published_at,
    url_hash: Digest::SHA256.hexdigest(url),
  )
end

# Seed a fixed dataset once and register the routes against it.
STORE = NewsCrystal::Storage::Database.open(":memory:")
STORE.save(article("https://a/1", "hackernews", Time.unix(1_000)))
STORE.save(article("https://a/2", "devto", Time.unix(2_000)))
STORE.save(article("https://a/3", "hackernews", Time.unix(3_000)))

Kemal.config.env = "development"
Kemal.config.logging = false
NewsCrystal::Api.setup(STORE)

describe NewsCrystal::Api do
  describe "GET /articles" do
    it "returns JSON with the articles, most recent first" do
      response = api_get("/articles")
      response.status_code.should eq(200)
      response.headers["Content-Type"].should start_with("application/json")

      body = JSON.parse(response.body)
      body["total"].as_i.should eq(3)
      body["articles"].as_a.size.should eq(3)
      body["articles"][0]["url"].as_s.should eq("https://a/3") # newest
      body["articles"][0]["published_at"].as_s.should_not be_empty
    end

    it "filters by source" do
      body = JSON.parse(api_get("/articles?source=hackernews").body)
      body["total"].as_i.should eq(2)
      body["source"].as_s.should eq("hackernews")
      body["articles"].as_a.all? { |entry| entry["source"].as_s == "hackernews" }.should be_true
    end

    it "paginates with page and per_page" do
      body = JSON.parse(api_get("/articles?per_page=1&page=2").body)
      body["page"].as_i.should eq(2)
      body["per_page"].as_i.should eq(1)
      body["articles"].as_a.size.should eq(1)
      body["articles"][0]["url"].as_s.should eq("https://a/2") # 2nd newest
    end
  end

  describe "GET /articles/:id" do
    it "returns a single article by id" do
      id = STORE.all.first.id
      response = api_get("/articles/#{id}")
      response.status_code.should eq(200)

      body = JSON.parse(response.body)
      body["id"].as_i64.should eq(id)
      body["url"].as_s.should eq("https://a/3")
    end

    it "returns 404 for an unknown id" do
      response = api_get("/articles/999999")
      response.status_code.should eq(404)
      JSON.parse(response.body)["error"].as_s.should eq("article not found")
    end

    it "returns 404 for a non-numeric id" do
      api_get("/articles/not-a-number").status_code.should eq(404)
    end
  end
end
