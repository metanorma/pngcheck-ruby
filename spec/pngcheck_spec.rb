require "spec_helper"

RSpec.describe do
  it "returns success status" do
    expect(Pngcheck.check_file("spec/examples/correct.png"))
      .to eq Pngcheck::STATUS_OK
  end
end
