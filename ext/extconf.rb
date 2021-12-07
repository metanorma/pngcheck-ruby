$: << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require "pngcheck/recipe"

recipe = Pngcheck::Recipe.new
recipe.cook
