require "../spec_helper"

describe NewsCrystal::Scraper::HackerNews do
  fixture = File.read(File.join(__DIR__, "..", "fixtures", "hacker_news.html"))
  articles = NewsCrystal::Scraper::HackerNews.new.parse(fixture)

  it "is a Source named hackernews" do
    NewsCrystal::Scraper::HackerNews.new.name.should eq("hackernews")
  end

  it "extracts only the well-formed stories" do
    # The third row is malformed (no title link) and must be skipped.
    articles.size.should eq(2)
  end

  it "parses title, link, author and date of the first story" do
    first = articles[0]
    first.title.should eq("First Story Title")
    first.url.should eq("https://example.com/first")
    first.source.should eq("hackernews")
    first.author.should eq("alice")
    first.published_at.should eq(Time.unix(1783500366))
  end

  it "resolves relative story URLs against the base URL" do
    second = articles[1]
    second.url.should eq("https://news.ycombinator.com/item?id=222")
    second.author.should eq("bob")
  end

  it "computes a URL hash for deduplication" do
    articles.each do |article|
      article.url_hash.should_not be_empty
    end
  end

  it "falls back to current time when the age title is unparseable" do
    now = Time.utc
    html = fixture.gsub("2026-07-08T08:46:06 1783500366", "not-a-timestamp")
    parsed = NewsCrystal::Scraper::HackerNews.new.parse(html)
    later = Time.utc

    parsed[0].published_at.should be >= now
    parsed[0].published_at.should be <= later
  end

  it "does not crash and returns no articles on empty HTML" do
    NewsCrystal::Scraper::HackerNews.new.parse("").should be_empty
  end
end
