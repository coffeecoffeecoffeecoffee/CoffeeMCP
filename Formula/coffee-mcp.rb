class CoffeeMcp < Formula
  desc "MCP server for the Coffee community events platform"
  homepage "https://github.com/coffeecoffeecoffeecoffee/CoffeeMCP"
  url "https://github.com/coffeecoffeecoffeecoffee/CoffeeMCP/releases/download/v0.1.0/CoffeeMCP-v0.1.0-macos.tar.gz"
  sha256 "PLACEHOLDER_REPLACE_AFTER_FIRST_RELEASE"
  license "MIT"
  version "0.1.0"

  depends_on :macos => :ventura

  def install
    bin.install "CoffeeMCP" => "coffee-mcp"
  end

  test do
    system bin/"coffee-mcp", "--help"
  end
end
