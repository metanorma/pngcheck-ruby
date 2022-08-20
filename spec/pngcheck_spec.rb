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

  it "analyzes correct buffer" do
    encoded = File.binread("spec/examples/correct.png")
    status, info = PngCheck.analyze_buffer(encoded)
    expect(status).to eql PngCheck::STATUS_OK
    expect(info).to include "OK"
  end

  it "analyzes corrupt buffer" do
    encoded = File.binread("spec/examples/corrupt.png")
    status, info = PngCheck.analyze_buffer(encoded)
    expect(status).to eql PngCheck::STATUS_MAJOR_ERROR
    expect(info).to include "data error"
  end

  it "analyzes trash in a buffer" do
    encoded = "[this is just a string]"
    status, info = PngCheck.analyze_buffer(encoded)
    expect(status).to eql PngCheck::STATUS_CRITICAL_ERROR
    expect(info).to include "neither a PNG or JNG image nor a MNG stream"
  end

  it "returns true on correct buffer check" do
    encoded = File.binread("spec/examples/correct.png")
    expect(PngCheck.check_buffer(encoded)).to eql true
  end

  it "raises an exception on corrupt buffer check" do
    encoded = File.binread("spec/examples/corrupt.png")
    expect do
      PngCheck.check_buffer(encoded)
    end.to raise_error(PngCheck::CorruptPngError)
  end

  it "raises an exception on trash buffer check" do
    encoded = "[this is just a string]"
    expect do
      PngCheck.check_buffer(encoded)
    end.to raise_error(PngCheck::CorruptPngError)
  end

  require "png"

  it "can be used with libpng-ruby" do
    encoded = File.binread("spec/examples/correct.png")
    begin
      expect(PngCheck.check_buffer(encoded)).to eql true
      dec = PNG::Decoder.new
      raw = dec << encoded
    rescue PngCheck::CorruptPngError => e
      puts "Exception #{e.message}"
    end
    f = "aaaaaaaaa"
    expect(raw.unpack(f)).to start_with
    "\xF4\xD1\r\xF4\xD1\r\xF4\xD1\r\xF4".unpack(f)
  end
end
