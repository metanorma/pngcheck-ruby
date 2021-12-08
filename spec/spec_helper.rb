require_relative "../lib/pngcheck"

RSpec.configure do |config| # rubocop:disable Style/SymbolProc
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end
