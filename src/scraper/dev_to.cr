require "./source"

module NewsCrystal
  module Scraper
    # Scraper for the Dev.to front page (https://dev.to/).
    #
    # Dev.to renders each story as a `div.crayons-story` card. Unlike Hacker
    # News, the title link, author and date all live inside that same card, so
    # no cross-row correlation is needed. Story URLs are relative ("/user/slug")
    # and resolved against the base URL.
    class DevTo < Source
      SOURCE_NAME = "devto"
      BASE_URL    = "https://dev.to/"

      def name : String
        SOURCE_NAME
      end

      def base_url : String
        BASE_URL
      end

      # Parses a Dev.to HTML page into articles.
      def parse(html : String) : Array(Storage::Article)
        parser = Lexbor.new(html)
        root = parser.root
        return [] of Storage::Article unless root

        articles = [] of Storage::Article
        root.css("div.crayons-story").each do |story|
          link = story.css("h2.crayons-story__title a").first?
          next unless link

          title = link.inner_text.strip
          url = absolute_url(link.attribute_by("href"))
          next if title.empty? || url.empty?

          author = story.css("a.crayons-story__secondary").first?.try(&.inner_text.strip) || ""
          published_at = parse_time(story.css("time").first?.try(&.attribute_by("datetime")))

          articles << build_article(title, url, author, published_at)
        end

        articles
      end

      # Dev.to timestamps are ISO 8601 in the `<time datetime="...">` attribute.
      # Falls back to now if missing or unparseable.
      private def parse_time(value : String?) : Time
        return Time.utc unless value
        Time.parse_rfc3339(value)
      rescue Time::Format::Error
        Time.utc
      end
    end
  end
end
