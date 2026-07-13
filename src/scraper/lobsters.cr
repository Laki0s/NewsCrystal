require "./source"

module NewsCrystal
  module Scraper
    # Scraper for the Lobsters front page (https://lobste.rs/).
    #
    # Each story is an `li.story`. The title link (`a.u-url`) and the submitting
    # author (`a.user_is_author`) live in the same list item; the publication
    # time is the `<time>` element in the byline. Text/self posts use a relative
    # link ("/s/shortid/...") resolved against the base URL.
    class Lobsters < Source
      SOURCE_NAME = "lobsters"
      BASE_URL    = "https://lobste.rs/"

      def name : String
        SOURCE_NAME
      end

      def base_url : String
        BASE_URL
      end

      # Parses a Lobsters HTML page into articles.
      def parse(html : String) : Array(Storage::Article)
        parser = Lexbor.new(html)
        root = parser.root
        return [] of Storage::Article unless root

        articles = [] of Storage::Article
        root.css("li.story").each do |story|
          link = story.css("a.u-url").first?
          next unless link

          title = link.inner_text.strip
          url = absolute_url(link.attribute_by("href"))
          next if title.empty? || url.empty?

          author = story.css("a.user_is_author").first?.try(&.inner_text.strip) || ""
          published_at = parse_time(story.css("time").first?)

          articles << build_article(title, url, author, published_at)
        end

        articles
      end

      # Lobsters `<time>` elements carry both a `data-at-unix` Unix timestamp and
      # a "%Y-%m-%d %H:%M:%S" (UTC) `datetime`. We prefer the numeric timestamp
      # and fall back to the string, then to now if both are missing/unparseable.
      private def parse_time(node : Lexbor::Node?) : Time
        return Time.utc unless node

        if unix = node.attribute_by("data-at-unix").try(&.to_i64?)
          return Time.unix(unix)
        end

        if datetime = node.attribute_by("datetime")
          return Time.parse(datetime, "%Y-%m-%d %H:%M:%S", Time::Location::UTC)
        end

        Time.utc
      rescue Time::Format::Error
        Time.utc
      end
    end
  end
end
