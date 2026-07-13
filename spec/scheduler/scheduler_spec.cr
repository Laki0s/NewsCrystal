require "../spec_helper"
require "digest/sha256"

# A Source stub that returns canned articles (or raises) without any network,
# so the scheduler can be tested deterministically.
private class FakeSource < NewsCrystal::Scraper::Source
  def initialize(@name : String, @articles : Array(NewsCrystal::Storage::Article) = [] of NewsCrystal::Storage::Article, @fail = false)
  end

  def name : String
    @name
  end

  def base_url : String
    "https://example.test/"
  end

  def parse(html : String) : Array(NewsCrystal::Storage::Article)
    @articles
  end

  # Override the network fetch with the canned result / failure.
  def fetch : Array(NewsCrystal::Storage::Article)
    raise "network down" if @fail
    @articles
  end
end

private def article(url : String)
  NewsCrystal::Storage::Article.new(
    title: "Title",
    url: url,
    source: "fake",
    author: "alice",
    published_at: Time.unix(1783500366),
    url_hash: Digest::SHA256.hexdigest(url),
  )
end

describe NewsCrystal::Scheduler do
  describe ".interval_from_env" do
    it "defaults to 15 minutes when unset" do
      ENV.delete("SCRAPE_INTERVAL_MINUTES")
      NewsCrystal::Scheduler.interval_from_env.should eq(15.minutes)
    end

    it "honors SCRAPE_INTERVAL_MINUTES" do
      ENV["SCRAPE_INTERVAL_MINUTES"] = "5"
      NewsCrystal::Scheduler.interval_from_env.should eq(5.minutes)
    ensure
      ENV.delete("SCRAPE_INTERVAL_MINUTES")
    end

    it "falls back to the default on a non-positive or invalid value" do
      ENV["SCRAPE_INTERVAL_MINUTES"] = "0"
      NewsCrystal::Scheduler.interval_from_env.should eq(15.minutes)
      ENV["SCRAPE_INTERVAL_MINUTES"] = "abc"
      NewsCrystal::Scheduler.interval_from_env.should eq(15.minutes)
    ensure
      ENV.delete("SCRAPE_INTERVAL_MINUTES")
    end
  end

  describe "#run_once" do
    it "stores articles from every source and returns the new count" do
      db = NewsCrystal::Storage::Database.open(":memory:")
      sources = [
        FakeSource.new("s1", [article("https://a.test/1"), article("https://a.test/2")]),
        FakeSource.new("s2", [article("https://a.test/3")]),
      ] of NewsCrystal::Scraper::Source

      scheduler = NewsCrystal::Scheduler.new(db, sources)
      scheduler.run_once.should eq(3)
      db.count.should eq(3)
      db.close
    end

    it "counts only newly inserted articles across runs (dedup)" do
      db = NewsCrystal::Storage::Database.open(":memory:")
      sources = [FakeSource.new("s1", [article("https://a.test/1")])] of NewsCrystal::Scraper::Source

      scheduler = NewsCrystal::Scheduler.new(db, sources)
      scheduler.run_once.should eq(1) # first pass inserts
      scheduler.run_once.should eq(0) # second pass: already known
      db.count.should eq(1)
      db.close
    end

    it "isolates a failing source so the others still run" do
      db = NewsCrystal::Storage::Database.open(":memory:")
      sources = [
        FakeSource.new("bad", fail: true),
        FakeSource.new("good", [article("https://a.test/ok")]),
      ] of NewsCrystal::Scraper::Source

      scheduler = NewsCrystal::Scheduler.new(db, sources)
      scheduler.run_once.should eq(1) # the good source still stored its article
      db.count.should eq(1)
      db.close
    end
  end

  describe "#start / #stop" do
    it "runs in a background fiber and stops on request" do
      db = NewsCrystal::Storage::Database.open(":memory:")
      sources = [FakeSource.new("s1", [article("https://a.test/1")])] of NewsCrystal::Scraper::Source

      scheduler = NewsCrystal::Scheduler.new(db, sources, interval: 1.hour)
      scheduler.running?.should be_false

      scheduler.start
      scheduler.running?.should be_true
      Fiber.yield # let the fiber run its first pass

      scheduler.stop
      scheduler.running?.should be_false
      db.count.should eq(1)
      db.close
    end
  end
end
