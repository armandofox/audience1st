---
layout: default
title: "Jekyll Docs Template"
---

### Quick Start: First time setup

1. Install Ruby
via [`rvm` (MacOS)](https://rvm.io) or [RubyInstaller
(Windows)](https://rubyinstaller.org/)

2. Install the `bundler` gem: `gem install bundler`

2. `git clone git@github.com:audience1st.git`

3. Change to the directory of the downloaded code tree

4. `git checkout gh-pages`

5. `bundle install`

### Editing/creating doc pages:

To edit an existing page, open the appropriate file in the `_posts`
subdirectory.

To create a new page, say `bin/jekyll-page `*title* *category* giving
the page's title and (new or existing) category, then edit the file that
the script says was just created.  You can use Markdown syntax within
files, but be sure to leave the top section of the file (its "header")
intact.

To rebuild and display the site locally, run `bin/jekyll serve`, and
point your browser to `http://localhost:4000` or `http://127.0.0.1:4000`

### Get Started

Start by [creating a new post](http://jekyllrb.com/docs/posts/) one of the categories listed in `_config.yml`. It will appear in the navigation on the left once recompiled. Or use the supplied script to make creating pages easier:

```bash
ruby bin/jekyll-page "Some Page Title" ref
```

#### Don't Forget

- Add your own content to this page (i.e. `index.md`) and change the `title`
- Change `title` and `subtitle` defined in `config.yml` for your site
- Set the `baseurl` in `_config.yml` for your repo if deploying to GitHub pages
