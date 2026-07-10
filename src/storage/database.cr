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

      def count : Int64
        @db.scalar("SELECT COUNT(*) FROM articles").as(Int64)
      end

      # Returns all stored articles, most recent first.
      def all : Array(Article)
        @db.query_all(
          "SELECT title, url, source, author, published_at, hash " \
          "FROM articles ORDER BY published_at DESC"
        ) do |row|
          Article.new(
            title: row.read(String),
            url: row.read(String),
            source: row.read(String),
            author: row.read(String),
            published_at: Time.unix(row.read(Int64)),
            url_hash: row.read(String),
          )
        end
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
