# frozen_string_literal: true

require "ffi"
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
  attach_function :pngcheck, [:file, :file_path, :searching, :file_out], :status

  class << self
    def check_file(path)
      file = LibC.fopen(path, "rb")
      pngcheck(file, path, 0, nil)
    end
  end
end
