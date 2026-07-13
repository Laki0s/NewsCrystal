require "./source"
require "./hacker_news"
require "./dev_to"
require "./lobsters"

module NewsCrystal
  # Scraping layer: HTTP fetching + HTML parsing of the news sources.
  # Hacker News (US2) plus Dev.to and Lobsters (US4), all behind the common
  # `Source` interface so the aggregator treats every site uniformly.
  module Scraper
    # Every source the aggregator knows about. New sources are added here so the
    # scheduler (US5) and any caller can iterate them without knowing the
    # concrete classes.
    def self.sources : Array(Source)
      [
        HackerNews.new,
        DevTo.new,
        Lobsters.new,
      ] of Source
    end

    # Fetches every known source and returns the combined article list. Each
    # article keeps its origin via its `source` tag; deduplication across
    # sources happens in storage (US3). Per-source error isolation and retries
    # are hardened in US9.
    def self.fetch_all : Array(Storage::Article)
      sources.flat_map(&.fetch)
    end
  end
end
