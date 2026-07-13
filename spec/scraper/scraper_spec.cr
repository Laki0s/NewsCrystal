require "../spec_helper"

describe NewsCrystal::Scraper do
  it "registers every source behind the common Source interface" do
    names = NewsCrystal::Scraper.sources.map(&.name)
    names.should contain("hackernews")
    names.should contain("devto")
    names.should contain("lobsters")
  end

  it "exposes each source as a Source" do
    NewsCrystal::Scraper.sources.each do |source|
      source.should be_a(NewsCrystal::Scraper::Source)
    end
  end
end
