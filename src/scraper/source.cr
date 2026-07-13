require "http/client"
require "digest/sha256"
require "lexbor"
require "../news_crystal/version"
require "../storage/article"

module NewsCrystal
  module Scraper
    # Common interface every source scraper must implement.
    #
    # Concrete sources (Hacker News in US2, Dev.to and Lobsters in US4) subclass
    # this so the aggregator can treat every source uniformly. The base class
    # also carries the fetch/URL/hash plumbing every source shares, leaving each
    # subclass with nothing but its own `parse` (the fragile, per-site HTML
    # logic) to implement.
    abstract class Source
      USER_AGENT = "NewsCrystal/#{NewsCrystal::VERSION} (+https://github.com/Laki0s/NewsCrystal)"

      # Human-readable identifier stored on each article (e.g. "hackernews").
      abstract def name : String

      # Front-page URL the source is fetched from; also the base used to resolve
      # relative story links.
      abstract def base_url : String

      # Parses a source HTML page into articles. Kept separate from `fetch` so it
      # can be unit-tested against a saved fixture, with no network dependency.
      abstract def parse(html : String) : Array(Storage::Article)

      # Fetches the front page over HTTP and returns the parsed articles. Shared
      # by every source; network robustness (timeouts, retries) is added in US9.
      def fetch : Array(Storage::Article)
        response = HTTP::Client.get(base_url, headers: HTTP::Headers{"User-Agent" => USER_AGENT})
        return [] of Storage::Article unless response.success?

        parse(response.body)
      end

      # Builds an article, tagging it with this source's `name` and computing the
      # URL fingerprint used for deduplication in storage (US3).
      protected def build_article(title : String, url : String, author : String, published_at : Time) : Storage::Article
        Storage::Article.new(
          title: title,
          url: url,
          source: name,
          author: author,
          published_at: published_at,
          url_hash: Digest::SHA256.hexdigest(url),
        )
      end

      # Absolute URLs are kept as-is; relative ones (e.g. "item?id=1" on HN or
      # "/user/slug" on Dev.to) are resolved against the source base URL.
      protected def absolute_url(href : String?) : String
        url = href.to_s.strip
        return url if url.empty? || url.starts_with?("http")

        "#{base_url}#{url.lstrip('/')}"
      end
    end
  end
end
