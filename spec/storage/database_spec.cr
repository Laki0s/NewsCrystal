require "../spec_helper"
require "digest/sha256"

private def sample_article(url : String, title = "Title", source = "hackernews")
  NewsCrystal::Storage::Article.new(
    title: title,
    url: url,
    source: source,
    author: "alice",
    published_at: Time.unix(1783500366),
    url_hash: Digest::SHA256.hexdigest(url),
  )
end

describe NewsCrystal::Storage::Database do
  it "creates the schema and starts empty" do
    db = NewsCrystal::Storage::Database.open(":memory:")
    db.count.should eq(0)
    db.close
  end

  it "saves a new article" do
    db = NewsCrystal::Storage::Database.open(":memory:")
    db.save(sample_article("https://example.com/a")).should be_true
    db.count.should eq(1)
    db.close
  end

  it "ignores duplicates by hash" do
    db = NewsCrystal::Storage::Database.open(":memory:")
    article = sample_article("https://example.com/a")

    db.save(article).should be_true  # first insert
    db.save(article).should be_false # same hash -> ignored
    db.count.should eq(1)
    db.close
  end

  it "counts only newly inserted articles in save_all" do
    db = NewsCrystal::Storage::Database.open(":memory:")
    a = sample_article("https://example.com/a")
    b = sample_article("https://example.com/b")

    db.save_all([a, b, a]).should eq(2) # a is repeated -> counted once
    db.count.should eq(2)
    db.close
  end

  it "reads back stored articles" do
    db = NewsCrystal::Storage::Database.open(":memory:")
    db.save(sample_article("https://example.com/a", title: "Hello"))

    stored = db.all
    stored.size.should eq(1)
    stored.first.title.should eq("Hello")
    stored.first.author.should eq("alice")
    stored.first.published_at.should eq(Time.unix(1783500366))
    db.close
  end
end
