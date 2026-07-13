require "log"
require "../storage/storage"
require "../scraper/scraper"

module NewsCrystal
  # Periodically re-scrapes every source and persists the results.
  #
  # The loop runs in a background fiber (`spawn`) so it never blocks the caller
  # (e.g. the API in US6). Each pass fetches all sources, stores the articles
  # (deduplicated in storage, US3) and logs a per-source summary. A source that
  # raises — a timeout, an unreachable site — is logged and skipped so it can
  # never take down the whole run or the loop.
  class Scheduler
    Log = ::Log.for("scheduler")

    # Fallback interval when nothing is configured.
    DEFAULT_INTERVAL = 15.minutes

    # Environment variable overriding the interval, expressed in minutes.
    INTERVAL_ENV = "SCRAPE_INTERVAL_MINUTES"

    getter interval : Time::Span
    getter? running : Bool

    def initialize(
      @database : Storage::Database,
      @sources : Array(Scraper::Source) = Scraper.sources,
      interval : Time::Span? = nil,
    )
      @interval = interval || self.class.interval_from_env
      @running = false
    end

    # Reads `SCRAPE_INTERVAL_MINUTES` from the environment; falls back to the
    # 15-minute default when it is unset, non-numeric or non-positive.
    def self.interval_from_env : Time::Span
      minutes = ENV[INTERVAL_ENV]?.try(&.to_i?)
      minutes && minutes > 0 ? minutes.minutes : DEFAULT_INTERVAL
    end

    # Runs a single scraping pass over every source and returns the number of
    # newly stored articles. Never raises: a failing source is logged and the
    # run continues with the next one.
    def run_once : Int32
      Log.info { "scrape run started (#{@sources.size} sources)" }
      total_new = 0

      @sources.each do |source|
        articles = source.fetch
        new_count = @database.save_all(articles)
        total_new += new_count
        Log.info { "  #{source.name}: #{articles.size} fetched, #{new_count} new" }
      rescue ex
        Log.error(exception: ex) { "  #{source.name}: failed, skipped" }
      end

      Log.info { "scrape run finished: #{total_new} new articles" }
      total_new
    end

    # Starts the periodic loop in a background fiber and returns immediately.
    # Calling it while already running is a no-op.
    def start : Nil
      return if @running
      @running = true

      spawn do
        Log.info { "scheduler started, interval=#{@interval}" }
        while @running
          run_once
          sleep @interval
        end
      end
    end

    # Stops the loop after the current pass finishes.
    def stop : Nil
      @running = false
    end
  end
end
