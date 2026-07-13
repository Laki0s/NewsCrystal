require "../spec_helper"

describe NewsCrystal::Scraper::Lobsters do
  fixture = File.read(File.join(__DIR__, "..", "fixtures", "lobsters.html"))
  articles = NewsCrystal::Scraper::Lobsters.new.parse(fixture)

  it "is a Source named lobsters" do
    NewsCrystal::Scraper::Lobsters.new.name.should eq("lobsters")
  end

  it "extracts only the well-formed stories" do
    # The third story is malformed (no u-url link) and must be skipped.
    articles.size.should eq(2)
  end

  it "parses title, link, author and date of the first story" do
    first = articles[0]
    first.title.should eq("First Lobsters Story")
    first.url.should eq("https://example.com/lob-first")
    first.source.should eq("lobsters")
    first.author.should eq("alice")
    first.published_at.should eq(Time.unix(1783500366))
  end

  it "resolves relative text-post URLs against the base URL" do
    second = articles[1]
    second.url.should eq("https://lobste.rs/s/bbb/second_text_story")
    second.author.should eq("bob")
  end

  it "computes a URL hash for deduplication" do
    articles.each do |article|
      article.url_hash.should_not be_empty
    end
  end

  it "falls back to current time when the byline time is unparseable" do
    now = Time.utc
    parsed = NewsCrystal::Scraper::Lobsters.new.parse(fixture)
    later = Time.utc

    # The second story carries a "broken-date" byline time.
    parsed[1].published_at.should be >= now
    parsed[1].published_at.should be <= later
  end

  it "does not crash and returns no articles on empty HTML" do
    NewsCrystal::Scraper::Lobsters.new.parse("").should be_empty
  end
end
