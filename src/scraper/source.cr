require "../storage/article"

module NewsCrystal
  module Scraper
    # Common interface every source scraper must implement.
    #
    # Concrete sources (Hacker News in US2, Dev.to and Lobsters in US4) subclass
    # this so the aggregator can treat every source uniformly.
    abstract class Source
      # Human-readable identifier stored on each article (e.g. "hackernews").
      abstract def name : String

      # Fetches and parses the latest articles for this source.
      abstract def fetch : Array(Storage::Article)
    end
  end
end
