module Pngcheck
  module LibC
    extend FFI::Library
    ffi_lib FFI::Library::LIBC

    typedef :pointer, :file

    attach_function :fopen, [:string, :string], :file
    attach_function :fclose, [:file], :int
  end
end
