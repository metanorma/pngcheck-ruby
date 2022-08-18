# frozen_string_literal: true

require "mini_portile2"
require "pathname"

module PngCheck
  class Recipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))

    def initialize
      super("pngcheck", "3.0.3")

      @files << {
        url: "http://www.libpng.org/pub/png/src/pngcheck-3.0.3.tar.gz",
        sha256: "c36a4491634af751f7798ea421321642f9590faa032eccb0dd5fb4533609dee6", # rubocop:disable Layout/LineLength
      }

      @target = ROOT.join(@target).to_s
      @printed = {}
    end

    def make_cmd
      if MiniPortile.windows?
        +"gcc -shared -fPIC -Wall -O -DUSE_ZLIB -o pngcheck.dll wrapper.c -lz"
      else
        +"gcc -shared -fPIC -Wall -O -DUSE_ZLIB -o pngcheck.so wrapper.c -lz"
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
      FileUtils.cp(ROOT.join("ext", "wrapper.c"), work_path, verbose: false)
    end

    def install
      libs = Dir.glob(File.join(work_path, "*"))
        .grep(%r{/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib|dll)$})

      FileUtils.cp_r(libs, ROOT.join("lib", "pngcheck"), verbose: false)
    end

    def execute(action, command, command_opts = {})
      super(action, command, command_opts.merge(debug: false))
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
