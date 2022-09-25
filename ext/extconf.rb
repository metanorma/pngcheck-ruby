# frozen_string_literal: true

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))
PNGCHECK_ARCH = "pngcheck-3.0.3.tar.gz"
require "pngcheck/recipe"

recipe = PngCheck::Recipe.new
recipe.cook
