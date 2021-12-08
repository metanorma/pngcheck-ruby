require "mini_portile2"
require "pathname"

module Pngcheck
  class Recipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("pngcheck", "3.0.3", make_command: make_command)

      @files << {
        url: "http://www.libpng.org/pub/png/src/pngcheck-3.0.3.tar.gz",
        sha256: "c36a4491634af751f7798ea421321642f9590faa032eccb0dd5fb4533609dee6", # rubocop:disable Layout/LineLength
      }

      @target = ROOT.join(@target).to_s
      @printed = {}
    end

    def make_command
      if MiniPortile.windows?
        "gcc -shared -fPIC -Wall -O -DUSE_ZLIB -o pngcheck.dll pngcheck.c -lz"
      else
        "gcc -shared -fPIC -Wall -O -DUSE_ZLIB -o pngcheck.so pngcheck.c -lz"
      end
    end

    def cook_if_not
      cook unless File.exist?(checkpoint)
    end

    def cook
      super

      FileUtils.touch(checkpoint)
    end

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{host}.installed")
    end

    def configure
      # noop
    end

    def install
      libs = Dir.glob(File.join(work_path, "*"))
        .grep(/\/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib|dll)$/)

      FileUtils.cp_r(libs, ROOT.join("lib", "pngcheck"), verbose: true)
    end

    def execute(action, command, command_opts = {})
      super(action, command, command_opts.merge(debug: true))
    end

    def message(text)
      return super unless text.start_with?("\rDownloading")

      match = text.match(/(\rDownloading .*)\(\s*\d+%\)/)
      pattern = match ? match[1] : text
      return if @printed[pattern]

      @printed[pattern] = true
      super
    end
  end
end
