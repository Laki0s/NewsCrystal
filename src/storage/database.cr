require "db"
require "sqlite3"
require "./article"

module NewsCrystal
  module Storage
    # SQLite-backed storage for aggregated articles.
    #
    # Deduplication relies on a UNIQUE index on the `hash` column (the URL
    # fingerprint carried by `Article#url_hash`): inserting an already-known
    # article is silently ignored via `INSERT OR IGNORE`.
    class Database
      def initialize(@db : DB::Database)
        migrate
      end

      # Opens (or creates) a SQLite database. Pass ":memory:" for an ephemeral
      # in-memory database (used by the specs).
      def self.open(path : String) : Database
        new(DB.open(connection_uri(path)))
      end

      def close : Nil
        @db.close
      end

      # Inserts an article, ignoring it if its hash is already stored.
      # Returns true when a new row was inserted, false on a duplicate.
      def save(article : Article) : Bool
        result = @db.exec(
          "INSERT OR IGNORE INTO articles " \
          "(title, url, source, author, published_at, hash) VALUES (?, ?, ?, ?, ?, ?)",
          article.title,
          article.url,
          article.source,
          article.author,
          article.published_at.to_unix,
          article.url_hash,
        )
        result.rows_affected > 0
      end

      # Saves many articles, returning how many were newly inserted.
      def save_all(articles : Enumerable(Article)) : Int32
        articles.count { |article| save(article) }
      end

      # Number of stored articles, optionally restricted to one source.
      def count(source : String? = nil) : Int64
        if source
          @db.scalar("SELECT COUNT(*) FROM articles WHERE source = ?", source).as(Int64)
        else
          @db.scalar("SELECT COUNT(*) FROM articles").as(Int64)
        end
      end

      # Returns all stored articles, most recent first.
      def all : Array(Article)
        @db.query_all(SELECT_COLUMNS + " ORDER BY published_at DESC") do |row|
          read_article(row)
        end
      end

      # Returns a page of articles, most recent first, optionally filtered by
      # source. `offset`/`limit` implement pagination for the REST API (US6).
      def page(limit : Int32, offset : Int32, source : String? = nil) : Array(Article)
        if source
          @db.query_all(
            SELECT_COLUMNS + " WHERE source = ? ORDER BY published_at DESC LIMIT ? OFFSET ?",
            source, limit, offset
          ) { |row| read_article(row) }
        else
          @db.query_all(
            SELECT_COLUMNS + " ORDER BY published_at DESC LIMIT ? OFFSET ?",
            limit, offset
          ) { |row| read_article(row) }
        end
      end

      # Looks up a single article by its row id; `nil` when unknown (REST 404).
      def find(id : Int64) : Article?
        @db.query_one?(SELECT_COLUMNS + " WHERE id = ?", id) { |row| read_article(row) }
      end

      # Columns read back into an `Article`, in the order `read_article` expects.
      SELECT_COLUMNS = "SELECT id, title, url, source, author, published_at, hash FROM articles"

      # Builds an `Article` from a result row matching `SELECT_COLUMNS`.
      private def read_article(row : DB::ResultSet) : Article
        Article.new(
          id: row.read(Int64),
          title: row.read(String),
          url: row.read(String),
          source: row.read(String),
          author: row.read(String),
          published_at: Time.unix(row.read(Int64)),
          url_hash: row.read(String),
        )
      end

      private def self.connection_uri(path : String) : String
        if path == ":memory:"
          # Keep a single connection so the in-memory database is shared.
          "sqlite3::memory:?max_pool_size=1"
        else
          "sqlite3://#{path}"
        end
      end

      private def migrate : Nil
        @db.exec <<-SQL
          CREATE TABLE IF NOT EXISTS articles (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            title        TEXT    NOT NULL,
            url          TEXT    NOT NULL,
            source       TEXT    NOT NULL,
            author       TEXT    NOT NULL,
            published_at INTEGER NOT NULL,
            hash         TEXT    NOT NULL UNIQUE
          )
          SQL
      end
    end
  end
end
