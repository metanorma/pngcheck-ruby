# frozen_string_literal: true

require "ffi"
require "tempfile"
require_relative "pngcheck/version"
require_relative "pngcheck/lib_c"

module Pngcheck
  class Error < StandardError; end

  STATUS_OK = 0

  extend FFI::Library

  lib_filename = FFI::Platform.windows? ? "pngcheck.dll" : "pngcheck.so"
  ffi_lib File.expand_path("pngcheck/#{lib_filename}", __dir__)
    .gsub("/", File::ALT_SEPARATOR || File::SEPARATOR)

  # int pngcheck(FILE *fp, char *_fname, int searching, FILE *fpOut)
  typedef :pointer, :file
  typedef :string, :file_path
  typedef :int, :searching
  typedef :pointer, :file_out
  typedef :int, :status
  attach_function :pngcheck, %i[file file_path searching file_out], :status

  class << self
    def check_file(path)
      file = LibC.fopen(path, "rb")

      stdout, stderr, code = capture3 do
        pngcheck(file, path, 0, nil)
      end

      puts "stderr: #{stderr}"
      puts "stdout: #{stdout}"
      puts "code:   #{code}"

      true
    end

    def capture3
      stderr = status = nil

      stdout = capture_stream($stdout) do
        stderr = capture_stream($stderr) do
          status = yield
        end
      end

      [stdout, stderr, status]
    end

    def capture_stream(stream_io)
      origin_stream = stream_io.dup

      Tempfile.open("captured_stream") do |captured_stream|
        stream_io.reopen(captured_stream)
        yield
        captured_stream.rewind
        return captured_stream.read
      end
    ensure
      stream_io.reopen(origin_stream)
    end
  end
end
