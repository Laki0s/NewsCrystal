require "kemal"
require "json"
require "../storage/storage"

module NewsCrystal
  # HTTP layer: REST API (Kemal) and the RSS/Atom feed.
  #
  # `setup` registers the JSON routes against a storage `Database`; `run` wires
  # them up and starts the Kemal server. The RSS/Atom feed lands in US8.
  module Api
    DEFAULT_PER_PAGE =  20
    MAX_PER_PAGE     = 100

    # Registers the REST routes against the given database. Call once before
    # starting Kemal (the specs call it directly and drive the handler chain).
    def self.setup(database : Storage::Database) : Nil
      # GET /articles — paginated list, optionally filtered by ?source=.
      # Query params: page (>=1), per_page (1..MAX_PER_PAGE), source.
      get "/articles" do |env|
        env.response.content_type = "application/json"

        page = (query_int(env, "page") || 1).clamp(1, Int32::MAX)
        per_page = (query_int(env, "per_page") || DEFAULT_PER_PAGE).clamp(1, MAX_PER_PAGE)
        source = env.params.query["source"]?.presence

        total = database.count(source)
        articles = database.page(per_page, (page - 1) * per_page, source)

        {
          page:     page,
          per_page: per_page,
          total:    total,
          source:   source,
          articles: articles.map { |article| article_json(article) },
        }.to_json
      end

      # GET /articles/:id — single article, 404 when the id is unknown/invalid.
      get "/articles/:id" do |env|
        env.response.content_type = "application/json"

        id = env.params.url["id"].to_i64?
        article = id ? database.find(id) : nil

        if article
          article_json(article).to_json
        else
          env.response.status_code = 404
          {error: "article not found"}.to_json
        end
      end
    end

    # Registers the routes and starts the blocking Kemal server. Used by the
    # runtime entry point; not called from specs.
    def self.run(database : Storage::Database, port : Int32 = 3000) : Nil
      setup(database)
      Kemal.config.port = port
      Kemal.run
    end

    # Parses a query param as an Int32, returning nil when absent or invalid.
    private def self.query_int(env, name : String) : Int32?
      env.params.query[name]?.try(&.to_i?)
    end

    # Public JSON shape of an article. `url_hash` (an internal dedup detail) is
    # intentionally not exposed.
    private def self.article_json(article : Storage::Article)
      {
        id:           article.id,
        title:        article.title,
        url:          article.url,
        source:       article.source,
        author:       article.author,
        published_at: article.published_at.to_rfc3339,
      }
    end
  end
end
