# frozen_string_literal: true

require "rbconfig"
require "mini_portile2"
require "pathname"
require "tmpdir"
require "shellwords"
require "open3"
require_relative "version"

ROOT = Pathname.new(File.expand_path("../..", __dir__))
require "#{ROOT}/ext/layout.rb"

module PngCheck
  class Recipe < MiniPortile
    COMMON_FLAGS = "-shared -fPIC -Wall -O -DUSE_ZLIB"

    def files_to_load_all
      @files << {
        url: "file:#{ROOT}/#{PNGCHECK_LOCAL}",
        sha256: "f8ff6033dc0008a90a468213a96ac5d72476b1e59378e267341fcf3734ebb2b3", # rubocop:disable Layout/LineLength
      }
    end

    def files_to_load_cross
      if target_platform.eql?("aarch64-linux") &&
          !host_platform.eql?("aarch64-linux")
        @files << {
          url: "http://ports.ubuntu.com/pool/main/z/zlib/zlib1g-dev_1.2.11.dfsg-2ubuntu1.3_arm64.deb", # rubocop:disable Layout/LineLength
          sha256: "0ebadc1ff2a70f0958d4e8e21ffa97d9fa4da23555eaae87782e963044a26fcf", # rubocop:disable Layout/LineLength
        }
      end
    end

    def initialize
      super("pngcheck", PNGCHECK_VER)
      files_to_load_all
      files_to_load_cross
      @target = ROOT.join(@target).to_s
      @printed = {}
    end

    def lib_filename
      @lib_filename ||=
        if MiniPortile.windows?
          "pngcheck.dll"
        else
          "pngcheck.so"
        end
    end

    def lib_workpath
      @lib_workpath ||= File.join(work_path, lib_filename)
    end

    def make_cmd
      "#{cc} #{cflags} #{COMMON_FLAGS} -o #{lib_filename} wrapper.c -lz"
    end

    def cook_if_not
      cook unless File.exist?(checkpoint)
    end

    def cook
      super
      FileUtils.touch(checkpoint)
    end

    def download_file_file(uri, full_path)
      if MiniPortile.windows?
        FileUtils.mkdir_p File.dirname(full_path)
        FileUtils.cp uri.to_s.delete_prefix("file:"), full_path
      else
        super
      end
    end

    def tmp_path
      "tmp/#{@host}/ports"
    end

    def checkpoint
      File.join(@target, "#{name}-#{version}-#{host}.installed")
    end

    def configure
      FileUtils.cp(ROOT.join("ext", "wrapper.c"), work_path, verbose: false)
      if target_platform.eql?("aarch64-linux") &&
          !host_platform.eql?("aarch64-linux")
        extract_file("#{work_path}/../data.tar.xz", work_path.to_s)
      end
    end

    def verify_lib
      begin
        out, = Open3.capture2("file #{lib_workpath}")
      rescue StandardError
        message("Failed to call file, skipped library verification ...\n")
        return
      end

      unless out.include?(target_format)
        raise "Invalid file format '#{out.strip}', '#{@target_format}' expected"
      end

      message("Verifying #{lib_workpath} ... OK\n")
    end

    def install
      libs = Dir.glob(File.join(work_path, "*"))
        .grep(%r{/(?:lib)?[a-zA-Z0-9\-]+\.(?:so|dylib|dll)$})

      FileUtils.cp_r(libs, ROOT.join("lib", "pngcheck"), verbose: false)
      verify_lib
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
          "x64-mingw32"
        when /\Ax86_64-w64-mingw-ucrt/
          "x64-mingw-ucrt"
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
        when /\Ax86_64.*linux.*/
          "ELF 64-bit LSB shared object, x86-64"
        when /\Ax64-mingw(32|-ucrt)/
          "PE32+ executable (DLL) (console) x86-64, for MS Windows"
        else
          "skip"
        end
    end

    def cc
      @cc ||=
        if target_platform.eql?(host_platform)
          "gcc"
        else
          case target_platform
          when "aarch64-linux"
            "aarch64-linux-gnu-gcc"
          when "arm64-darwin"
            "gcc -target arm64-apple-macos11"
          else
            "gcc"
          end
        end
    end

    def cflags
      @cflags ||=
        if target_platform.eql?("aarch64-linux") &&
            !host_platform.eql?("aarch64-linux")
          "-I./usr/include -L./usr/lib/#{target_platform}-gnu"
        else
          ""
        end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength
  end
end
