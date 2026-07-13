require "../spec_helper"

describe NewsCrystal::Scraper::DevTo do
  fixture = File.read(File.join(__DIR__, "..", "fixtures", "dev_to.html"))
  articles = NewsCrystal::Scraper::DevTo.new.parse(fixture)

  it "is a Source named devto" do
    NewsCrystal::Scraper::DevTo.new.name.should eq("devto")
  end

  it "extracts only the well-formed stories" do
    # The third card is malformed (no title link) and must be skipped.
    articles.size.should eq(2)
  end

  it "parses title, link, author and date of the first story" do
    first = articles[0]
    first.title.should eq("First Dev.to Post")
    first.url.should eq("https://dev.to/alice/first-devto-post-123")
    first.source.should eq("devto")
    first.author.should eq("alice")
    first.published_at.should eq(Time.utc(2026, 7, 10, 9, 0, 0))
  end

  it "resolves relative story URLs against the base URL" do
    second = articles[1]
    second.url.should eq("https://dev.to/bob/second-devto-post-456")
    second.author.should eq("bob")
  end

  it "computes a URL hash for deduplication" do
    articles.each do |article|
      article.url_hash.should_not be_empty
    end
  end

  it "falls back to current time when the datetime is unparseable" do
    now = Time.utc
    parsed = NewsCrystal::Scraper::DevTo.new.parse(fixture)
    later = Time.utc

    # The second story carries a "not-a-date" datetime.
    parsed[1].published_at.should be >= now
    parsed[1].published_at.should be <= later
  end

  it "does not crash and returns no articles on empty HTML" do
    NewsCrystal::Scraper::DevTo.new.parse("").should be_empty
  end
end
