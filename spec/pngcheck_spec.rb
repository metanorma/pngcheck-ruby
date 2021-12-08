require "spec_helper"

RSpec.describe do
  it "returns success status" do
    expect(Pngcheck.check_file("spec/examples/correct.png"))
      .to eq true
  end
end
