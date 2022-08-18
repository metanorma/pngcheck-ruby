# frozen_string_literal: true

require "spec_helper"

RSpec.describe do
  it "analyzes correct file" do
    status, info = PngCheck.analyze_file("spec/examples/correct.png")
    expect(status).to eql PngCheck::STATUS_OK
    expect(info).to include "OK"
    #    puts "--> info: #{info}\n"
  end
  it "analyzes broken file" do
    status, info = PngCheck.analyze_file("spec/examples/corrupt.png")
    expect(status).to eql PngCheck::STATUS_MAJOR_ERROR
    expect(info).to include "data error"
    #    puts "--> info: #{info}\n"
  end
  it "analyzes missing file" do
    status, info = PngCheck.analyze_file("spec/examples/nofile.png")
    expect(status).to eql PngCheck::STATUS_CRITICAL_ERROR
    expect(info).to include "No such file or directory"
    #    puts "--> info: #{info}\n"
  end
  it "returns true on correct file check" do
    expect(PngCheck.check_file("spec/examples/correct.png")).to eql true
  end
  it "raises an exception on corrupt file check" do
    expect do
      PngCheck.check_file("spec/examples/corrupt.png")
    end.to raise_error(PngCheck::CorruptPngError)
  end
  it "raises an exception on missing file check" do
    expect do
      PngCheck.check_file("spec/examples/nofile.png")
    end.to raise_error(PngCheck::CorruptPngError)
  end
end
