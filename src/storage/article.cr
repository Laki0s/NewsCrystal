module NewsCrystal
  module Storage
    # Domain model representing a single aggregated article.
    #
    # `hash` is a fingerprint derived from the URL, used to detect and ignore
    # duplicates across scraping runs (see US3).
    struct Article
      getter title : String
      getter url : String
      getter source : String
      getter published_at : Time
      getter hash : String

      def initialize(
        @title : String,
        @url : String,
        @source : String,
        @published_at : Time,
        @hash : String,
      )
      end
    end
  end
end
