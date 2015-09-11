
require "spec_helper"

describe Kickstart::Version do
  before do
    @version = described_class.new "F21"
  end

  context "#at_least?" do
    it "returns false for higher version numbers" do
      expect(@version.at_least?("F99")).to be_falsy
    end

    it "returns true for lower version numbers" do
      expect(@version.at_least?("F1")).to be_truthy
    end

    it "returns true for the same version number" do
      expect(@version.at_least?("F21")).to be_truthy
    end
  end
end
