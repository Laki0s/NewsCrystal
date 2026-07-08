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
      author: "alice",
      published_at: published,
      url_hash: "abc123",
    )

    article.title.should eq("Hello Crystal")
    article.url.should eq("https://example.com/hello")
    article.source.should eq("hackernews")
    article.author.should eq("alice")
    article.published_at.should eq(published)
    article.url_hash.should eq("abc123")
  end
end
