source "https://rubygems.org"
# Hello! This is where you manage which Jekyll version is used to run.
# When you want to use a different version, change it below, save the
# file and run `bundle install`. Run Jekyll with `bundle exec`, like so:
#
#     bundle exec jekyll serve
#
# This will help ensure the proper Jekyll version is running.
# Happy Jekylling!
#
# NOTE: the `github-pages` meta-gem is deliberately not used here: it pins
# commonmarker < 1.0, which refuses to install on Ruby >= 4.0. The gems below
# mirror what GitHub Pages actually builds this site with (Jekyll 3.10 +
# Minima 2.5 + kramdown GFM), so local builds stay faithful.
gem "jekyll", "~> 3.10.0"
# This is the default theme for new Jekyll sites. You may change this to anything you like.
gem "minima", "~> 2.5.1"
# Markdown parser GitHub Pages uses (normally pulled in by the github-pages gem).
gem "kramdown-parser-gfm", "~> 1.1"

# If you have any plugins, put them here!
group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.17"
  gem "jekyll-paginate"
end

# Formerly-default gems dropped from the Ruby stdlib (3.4+ / 4.0) that Jekyll 3.x
# and its dependencies still require.
gem "base64"
gem "bigdecimal"
gem "csv"
gem "logger"
gem "ostruct"

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1", :platforms => [:windows]

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]
