class CoffeeMcp < Formula
  desc "MCP server for the Coffee community events platform"
  homepage "https://github.com/coffeecoffeecoffeecoffee/CoffeeMCP"
  url "https://github.com/coffeecoffeecoffeecoffee/CoffeeMCP/releases/download/v0.1.1/CoffeeMCP-v0.1.1-macos.tar.gz"
  sha256 "ae28826df65bb5fbab8d4fe66f0ed363f464f66d1087dc16efeeaa32393667f2"
  license "MIT"
  version "0.1.1"

  depends_on :macos => :ventura

  def install
    bin.install "CoffeeMCP" => "coffee-mcp"
  end

  test do
    system bin/"coffee-mcp", "--help"
  end
end
