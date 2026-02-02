# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Install dependencies (gems installed locally to vendor/bundle)
bundle install

# Serve locally with live reload (development)
bundle exec jekyll serve

# Build for production
bundle exec jekyll build
```

Build output goes to `_site/`. Both `_site/` and `vendor/` are gitignored.

## Project Overview

This is Elias Farhan's personal technical blog and portfolio, built with Jekyll (~3.10.0) and hosted on GitHub Pages. The site covers graphics programming (Vulkan, OpenGL ES, raytracing), game development, and educational content.

## Architecture

- **Posts**: `_posts/` contains dated markdown files (`YYYY-MM-DD-title.markdown`) with YAML front matter
- **Drafts**: `_drafts/` for unpublished posts
- **Layouts**: `_layouts/` (default, home, post, page) - layouts inherit from `default`
- **Includes**: `_includes/` for partials (header.html, social.html, google_analytics.html)
- **Slides**: `slides/` contains Markdeep-based presentation slides (vulkan_course.md.html, vulkan_raytracing_course.md.html)
- **Assets**: `assets/` for SCSS and WebGL demos; `images/` organized by year

## Content Conventions

- Posts use `<!--more-->` as excerpt separator
- Front matter fields: `layout`, `title`, `date`, `categories`
- Images stored in `images/YYYY/` directories
- Main styling in `assets/main.scss` (extends Minima theme)

## Site Configuration

`_config.yml` contains Jekyll settings, social links, and plugin configuration. Key plugins: jekyll-feed, jekyll-paginate.
