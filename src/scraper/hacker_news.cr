require "./source"

module NewsCrystal
  module Scraper
    # Scraper for the Hacker News front page (https://news.ycombinator.com/).
    #
    # The HTML is parsed with lexbor. Each story lives in a `tr.athing` row,
    # while its author and publication date live in the *following* `td.subtext`
    # row. The two are correlated by the Hacker News item id rather than by
    # fragile sibling navigation.
    class HackerNews < Source
      SOURCE_NAME = "hackernews"
      BASE_URL    = "https://news.ycombinator.com/"

      def name : String
        SOURCE_NAME
      end

      def base_url : String
        BASE_URL
      end

      # Parses a Hacker News HTML page into articles.
      def parse(html : String) : Array(Storage::Article)
        parser = Lexbor.new(html)
        root = parser.root
        return [] of Storage::Article unless root

        subtext = collect_subtext(root)

        articles = [] of Storage::Article
        root.css("tr.athing").each do |row|
          id = row.attribute_by("id")
          link = row.css("span.titleline a").first?
          next unless id && link

          title = link.inner_text.strip
          url = absolute_url(link.attribute_by("href"))
          next if title.empty? || url.empty?

          author, published_at = subtext[id]? || {"", Time.utc}
          articles << build_article(title, url, author, published_at)
        end

        articles
      end

      # Builds a map of item id => {author, published_at} from the subtext rows.
      private def collect_subtext(root : Lexbor::Node) : Hash(String, {String, Time})
        meta = {} of String => {String, Time}

        root.css("td.subtext").each do |sub|
          age = sub.css("span.age").first?
          next unless age

          id = extract_id(age.css("a").first?.try(&.attribute_by("href")))
          next unless id

          author = sub.css("a.hnuser").first?.try(&.inner_text) || ""
          meta[id] = {author, parse_time(age.attribute_by("title"))}
        end

        meta
      end

      # Extracts the numeric id from a link like "item?id=48829312".
      private def extract_id(href : String?) : String?
        return unless href
        href.match(/id=(\d+)/).try(&.[1])
      end

      # The HN age `title` looks like "2026-07-08T08:46:06 1783500366".
      # We rely on the trailing Unix timestamp; fall back to now if unparseable.
      private def parse_time(title : String?) : Time
        if title && (ts = title.split(' ').last?.try(&.to_i64?))
          Time.unix(ts)
        else
          Time.utc
        end
      end
    end
  end
end
