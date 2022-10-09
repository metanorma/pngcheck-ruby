# frozen_string_literal: true

require "ffi"
require "tempfile"
require_relative "pngcheck/version"

module PngCheck
  STATUS_OK = 0
  STATUS_WARNING = 1        # an error in some circumstances but not in all
  STATUS_MINOR_ERROR = 3    # minor spec errors (e.g., out-of-range values)
  STATUS_MAJOR_ERROR = 4    # file corruption, invalid chunk length/layout, etc.
  STATUS_CRITICAL_ERROR = 5 # unexpected EOF or other file(system) error

  EMPTY_IMAGE = "Image is empty"

  class CorruptPngError < StandardError
    def initialize(msg, sts = STATUS_MAJOR_ERROR)
      super(msg)
      @status = sts
    end

    def status
      @status
    end
  end

  class EmptyPngError < CorruptPngError
    def initialize(msg = EMPTY_IMAGE)
      super(msg, STATUS_CRITICAL_ERROR)
    end
  end

  EXTRA_MESSAGE_SIZE = 1024

  extend FFI::Library

  lib_filename = FFI::Platform.windows? ? "pngcheck.dll" : "pngcheck.so"
  ffi_lib File.expand_path("pngcheck/#{lib_filename}", __dir__)
    .gsub("/", File::ALT_SEPARATOR || File::SEPARATOR)

  # int pngcheck_file(char *fname, char *cname, char *extra_message)
  typedef :string, :file_path
  typedef :pointer, :extra_message
  typedef :int, :status
  attach_function :pngcheck_file, %i[file_path file_path extra_message],
                  :status
  # int pngcheck_string(char *data, int size, char *cname, char *extra_message)
  typedef :pointer, :data
  typedef :int, :size
  attach_function :pngcheck_buffer, %i[data size file_path extra_message],
                  :status

  @@semaphore = Mutex.new

  class << self
    def analyze_file(path)
      return [STATUS_CRITICAL_ERROR, EMPTY_IMAGE] if File.zero? path

      do_analyze_file(path)
    end

    def check_file(path)
      status, info = analyze_file(path)
      raise EmptyPngError.new if info.eql? EMPTY_IMAGE
      raise CorruptPngError.new(info, status) unless status == STATUS_OK

      true
    end

    def analyze_buffer(data)
      return [STATUS_CRITICAL_ERROR, EMPTY_IMAGE] if data.empty?

      do_analyze_buffer(data)
    end

    def check_buffer(data)
      status, info = analyze_buffer(data)
      raise EmptyPngError.new if info.eql? EMPTY_IMAGE
      raise CorruptPngError.new(info, status) unless status == STATUS_OK

      true
    end

    private

    def do_analyze_file(path)
      Tempfile.open("captured-stream-") do |captured_stream|
        extra_msg = FFI::Buffer.alloc_out(EXTRA_MESSAGE_SIZE, 1, false)
        @@semaphore.lock
        status = pngcheck_file(path, captured_stream.path, extra_msg)
        @@semaphore.unlock
        # we assume that pngcheck_file returns either captured_stream
        # or extra message but not both

        [status, captured_stream.read + extra_msg.get_string(0)]
      end
    end

    def do_analyze_buffer(data)
      Tempfile.open("captured-stream-") do |captured_stream|
        extra_msg = FFI::Buffer.alloc_out(EXTRA_MESSAGE_SIZE, 1, false)
        mem_buf = FFI::MemoryPointer.new(:char, data.bytesize)
        mem_buf.put_bytes(0, data)
        @@semaphore.lock
        status = pngcheck_buffer(mem_buf, data.bytesize, captured_stream.path,
                                 extra_msg)
        @@semaphore.unlock
        [status, captured_stream.read + extra_msg.get_string(0)]
      end
    end
  end
end
