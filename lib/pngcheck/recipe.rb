# frozen_string_literal: true

require "rbconfig"
require "mini_portile2"
require "pathname"
require "tmpdir"
require "shellwords"
require "open3"
require_relative "version"

module PngCheck
  class Recipe < MiniPortile
    ROOT = Pathname.new(File.expand_path("../..", __dir__))
    COMMON_FLAGS = "-shared -fPIC -Wall -O -DUSE_ZLIB"

    def files_to_load
      @files << {
        url: "http://www.libpng.org/pub/png/src/pngcheck-3.0.3.tar.gz",
        sha256: "c36a4491634af751f7798ea421321642f9590faa032eccb0dd5fb4533609dee6", # rubocop:disable Layout/LineLength
      }
      if target_platform.eql?("aarch64-linux")
        @files << {
          url: "http://ports.ubuntu.com/pool/main/z/zlib/zlib1g-dev_1.2.11.dfsg-2ubuntu1.3_arm64.deb", # rubocop:disable Layout/LineLength
          sha256: "0ebadc1ff2a70f0958d4e8e21ffa97d9fa4da23555eaae87782e963044a26fcf", # rubocop:disable Layout/LineLength
        }
      end
    end

    def initialize
      super("pngcheck", "3.0.3")
      files_to_load
      @target = ROOT.join(@target).to_s
      @printed = {}
    end

    def extract_file(file, target)
      if File.extname(file).eql?(".deb")
        message "Extracting #{file} into #{target}... "
        execute("extract", ["dpkg", "-x", file, target],
                { cd: Dir.pwd, initial_message: false })
      else
        super(file, target)
      end
    end

    def make_cmd
      if MiniPortile.windows?
        "gcc #{COMMON_FLAGS} -o pngcheck.dll wrapper.c -lz"
      else
        "#{cc} #{cflags} #{COMMON_FLAGS} -o pngcheck.so wrapper.c -lz"
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
      if target_platform.eql?("aarch64-linux")
        extract_file("#{work_path}/../data.tar.xz", work_path.to_s)
      end
    end

    def libs_to_verify
      Dir.glob(ROOT.join("lib", "pngcheck",
                         "pngcheck.{so,dylib,dll}"))
    end

    def verify_libs
      libs_to_verify.each do |l|
        out, st = Open3.capture2("file #{l}")
        out = out.strip

        raise "Failed to query file #{l}: #{out}" unless st.exitstatus.zero?

        if out.include?(target_format)
          message("Verifying #{l} ... OK\n")
        else
          raise "Invalid file format '#{out}', '#{@target_format}' expected"
        end
      end
    end

    def install
      libs = Dir.glob(File.join(work_path, "*"))
        .grep(%r{/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib|dll)$})

      FileUtils.cp_r(libs, ROOT.join("lib", "pngcheck"), verbose: false)
      verify_libs
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

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    def host_platform
      @host_platform ||=
        case @host
        when /\Ax86_64-w64-mingw32/
          "w64-mingw32"
        when /\Ax86_64-w64-mingw-ucrt/
          "w64-mingw-ucrt"
        when /\Ax86_64.*linux/
          "x86_64-linux"
        when /\A(arm64|aarch64).*linux/
          "aarch64-linux"
        when /\Ax86_64.*(darwin|macos|osx)/
          "x86_64-darwin"
        when /\A(arm64|aarch64).*(darwin|macos|osx)/
          "arm64-darwin"
        else
          @host
        end
    end

    def target_platform
      @target_platform ||=
        case ENV.fetch("target_platform", nil)
        when /\A(arm64|aarch64).*(darwin|macos|osx)/
          "arm64-darwin"
        when /\Ax86_64.*(darwin|macos|osx)/
          "x86_64-darwin"
        when /\A(arm64|aarch64).*linux/
          "aarch64-linux"
        else
          ENV.fetch("target_platform", host_platform)
        end
    end

    def target_format
      @target_format ||=
        case target_platform
        when "arm64-darwin"
          "Mach-O 64-bit dynamically linked shared library arm64"
        when "x86_64-darwin"
          "Mach-O 64-bit dynamically linked shared library x86_64"
        when "aarch64-linux"
          "ELF 64-bit LSB shared object, ARM aarch64"
        when "x86_64-linux"
          "ELF 64-bit LSB shared object, x86-64"
        when /\Aw64-mingw(32|-ucrt)/
          "PE32+ executable (DLL) (console) x86-64, for MS Windows"
        else
          "skip"
        end
    end

    def cc
      @cc ||=
        case target_platform
        when "aarch64-linux"
          "aarch64-linux-gnu-gcc"
        when "x86_64-linux"
          "x86_64-linux-gnu-gcc"
        when "arm64-darwin"
          "gcc -target arm64-apple-macos11"
        else
          "gcc"
        end
    end

    def cflags
      @cflags ||=
        case target_platform
        when "aarch64-linux"
          "-I./usr/include -L./usr/lib/#{target_platform}-gnu"
        else
          ""
        end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
  end
end
