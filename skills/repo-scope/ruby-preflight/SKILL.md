---
description: "Pre-PR checklist for Ruby: bundle install, lint (RuboCop), type-check (Sorbet/RBS) if configured, and tests (RSpec or Minitest)."
---

# Ruby Preflight Checklist

Run these before creating any PR or reporting a Ruby task complete.

## 0. Dependencies

```bash
bundle check || bundle install
```

Every other command below assumes `bundle exec` prefix — don't use system gems.

## 1. Syntax check (fast)

```bash
bundle exec ruby -wc $(git ls-files '*.rb' | head -50)
```

Catches parse errors without running the code. Keep the file list short — Ruby parsing is fast but `xargs` blows past `ARG_MAX` on big repos.

## 2. Lint — RuboCop

```bash
bundle exec rubocop --fail-level=warning
# Auto-fix safe offenses: bundle exec rubocop -a
# Auto-fix all offenses (review before committing): bundle exec rubocop -A
```

If the repo uses `standardrb` instead of RuboCop: `bundle exec standardrb`.

## 3. Type check (if Sorbet / RBS / Steep configured)

```bash
# Sorbet
test -d sorbet && bundle exec srb tc
# Steep (RBS-based)
test -f Steepfile && bundle exec steep check
```

Skip silently if neither is configured — don't introduce type checking in preflight.

## 4. Tests

```bash
# RSpec
test -d spec && bundle exec rspec
bundle exec rspec spec/path/to_spec.rb       # focused file
bundle exec rspec -e 'describes behaviour'   # focused example

# Minitest (often via rake)
test -f Rakefile && grep -q 'test' Rakefile && bundle exec rake test
```

For Rails: `bin/rails test` for framework tests, or `bin/rails test:all` including system tests. Use `RAILS_ENV=test` explicitly if your shell has a non-test default.

## 5. Security (optional)

```bash
bundle exec brakeman --no-pager 2>/dev/null | tail -10   # Rails apps only
bundle-audit check --update 2>/dev/null | tail -5        # any Ruby project with a Gemfile
```

Run only if the PR touches dependencies or auth/authz code.

## Done?

Report completion only after lint, type-check (if configured), and tests pass. Do not suppress RuboCop offenses with `# rubocop:disable` without a comment explaining why.
