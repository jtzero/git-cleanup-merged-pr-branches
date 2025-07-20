class GCMPB < Formula
  desc "Git command to cleanup merged PR branches"
  homepage "https://gitlab.com/jtzero/git-cleanup-merged-pr-branches"
  url "https://gitlab.com/jtzero/git-cleanup-merged-pr-branches/-/archive/d2d35cc571f6b61692629a38101089555beddbf0/git-cleanup-merged-pr-branches-d2d35cc571f6b61692629a38101089555beddbf0.tar.gz"
  sha256 ""
  license "Apache-2.0"

  depends_on "coreutils"
  depends_on "git"
  depends_on "jq"
  depends_on "gh" => :optional
  depends_on "glab" => :optional
  depends_on "azure-cli" => :optional

  def install
    prefix.install "bin"
    prefix.install "lib"
  end

  test do
    system "#{bin}/git-cleanup-merged-pr-branches", "--version"
  end
end
