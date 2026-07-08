module NewsCrystal
  module Storage
    # Domain model representing a single aggregated article.
    #
    # `url_hash` is a fingerprint derived from the URL, used to detect and
    # ignore duplicates across scraping runs (see US3). It maps to the `hash`
    # column of the `articles` table. The field is intentionally *not* named
    # `hash` to avoid shadowing Crystal's `Object#hash` (used by Hash/Set).
    struct Article
      getter title : String
      getter url : String
      getter source : String
      getter published_at : Time
      getter url_hash : String

      def initialize(
        @title : String,
        @url : String,
        @source : String,
        @published_at : Time,
        @url_hash : String,
      )
      end
    end
  end
end
