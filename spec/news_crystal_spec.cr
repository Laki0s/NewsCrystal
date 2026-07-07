require "./spec_helper"

describe NewsCrystal do
  it "exposes a version" do
    NewsCrystal::VERSION.should eq("0.1.0")
  end
end

describe NewsCrystal::Storage::Article do
  it "builds an article with its fields" do
    published = Time.utc(2026, 7, 6, 12, 0, 0)
    article = NewsCrystal::Storage::Article.new(
      title: "Hello Crystal",
      url: "https://example.com/hello",
      source: "hackernews",
      published_at: published,
      hash: "abc123",
    )

    article.title.should eq("Hello Crystal")
    article.url.should eq("https://example.com/hello")
    article.source.should eq("hackernews")
    article.published_at.should eq(published)
    article.hash.should eq("abc123")
  end
end
