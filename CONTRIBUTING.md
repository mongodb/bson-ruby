Contributing
============

Code Conventions
----------------

Code style should fall in line with the style guide outlined by
[Github](https://github.com/styleguide/ruby)

Testing
-------

Bug fixes and new features should always have the appropriate specs, and the
specs should follow the following guidelines:

- Prefer `let` and `let!` over the use of instance variables and `subject`.
- Prefer `expect(...).to eq(...) syntax over `...should eq(...)`.
- Use shared examples to reduce duplication.
- Use `describe "#method"` for instance method specs.
- Use `describe ".method"` for class method specs.
- Use `context` blocks to set up conditions.
- Always provide descriptive specifications via `it`.

Specs can be automatically run with Guard, via `bundle exec guard`

Before commiting, run `rake` to ensure all specs pass with both pure Ruby and
the native extensions.

Git Etiquette
-------------

Please follow the commit message guidelines as outlined
[in this blog post](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

If the commit fixes a bug, please add the JIRA number on the last line:

```
[ close RUBY-492 ]
```

Please ensure that only one feature/bug fix is in each pull request, and
that it is squashed into a single commit.
