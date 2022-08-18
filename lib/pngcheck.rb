# frozen_string_literal: true

require "ffi"
require "tempfile"
require_relative "pngcheck/version"

module PngCheck
  class CorruptPngError < StandardError; end

  STATUS_OK = 0
  STATUS_WARNING = 1        # an error in some circumstances but not in all
  STATUS_MINOR_ERROR = 3    # minor spec errors (e.g., out-of-range values)
  STATUS_MAJOR_ERROR = 4    # file corruption, invalid chunk length/layout, etc.
  STATUS_CRITICAL_ERROR = 5 # unexpected EOF or other file(system) error

  EXTRA_MESSAGE_SIZE = 1024

  extend FFI::Library

  lib_filename = FFI::Platform.windows? ? "pngcheck.dll" : "pngcheck.so"
  ffi_lib File.expand_path("pngcheck/#{lib_filename}", __dir__)
    .gsub("/", File::ALT_SEPARATOR || File::SEPARATOR)

  # int pngcheck_wrapped(FILE *fp, char * cname)
  typedef :string, :file_path
  typedef :pointer, :extra_message
  typedef :int, :status
  attach_function :pngcheck_wrapped, %i[file_path file_path extra_message],
                  :status

  class << self
    def analyze_file(path)
      Tempfile.open("captured-stream-") do |captured_stream|
        extra_msg = FFI::Buffer.alloc_out(EXTRA_MESSAGE_SIZE, 1, false)
        status = pngcheck_wrapped(path, captured_stream.path, extra_msg)
        # we assume that pngcheck_wrapped returns either captured_stream
        # or extra message but not both
        [status, captured_stream.read + extra_msg.get_string(16)]
      end
    end

    def check_file(path)
      status, info = analyze_file(path)
      raise CorruptPngError.new info unless status == STATUS_OK

      true
    end
  end
end
