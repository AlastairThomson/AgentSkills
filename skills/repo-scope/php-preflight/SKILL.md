---
description: "Pre-PR checklist for PHP: syntax check, Composer validation, style (PHP_CodeSniffer / PHP-CS-Fixer), static analysis (PHPStan / Psalm), and tests (PHPUnit / Pest)."
---

# PHP Preflight Checklist

Run these before creating any PR or reporting a PHP task complete.

## 0. Dependencies

```bash
composer validate --strict --no-check-all
composer install --no-interaction --prefer-dist    # idempotent; fast if already installed
```

`composer validate` catches `composer.json` mistakes early.

## 1. Syntax check (fast)

```bash
# `php -l` per file — xargs in chunks to avoid ARG_MAX
git ls-files '*.php' | xargs -n50 -P4 -I{} php -l {} 2>&1 | grep -v '^No syntax errors'
```

Empty output means clean.

## 2. Style

```bash
# PHP_CodeSniffer
test -f phpcs.xml -o -f phpcs.xml.dist && vendor/bin/phpcs
# Fix: vendor/bin/phpcbf

# Or PHP-CS-Fixer
test -f .php-cs-fixer.dist.php -o -f .php-cs-fixer.php && \
  vendor/bin/php-cs-fixer fix --dry-run --diff
# Fix: vendor/bin/php-cs-fixer fix
```

If neither tool is configured, skip — don't introduce style rules in preflight.

## 3. Static analysis

```bash
# PHPStan
test -f phpstan.neon -o -f phpstan.neon.dist && vendor/bin/phpstan analyse --no-progress

# Or Psalm
test -f psalm.xml -o -f psalm.xml.dist && vendor/bin/psalm --no-progress
```

Both can be configured with a baseline file (`phpstan-baseline.neon`, `psalm-baseline.xml`) — leave baseline entries alone, only fix new errors.

## 4. Tests

```bash
# PHPUnit
test -f phpunit.xml -o -f phpunit.xml.dist && vendor/bin/phpunit
vendor/bin/phpunit --filter 'TestMethodName'                  # focused
vendor/bin/phpunit tests/Unit/Foo/BarTest.php                 # one file

# Pest
test -f pest.config.php -o -f tests/Pest.php && vendor/bin/pest
vendor/bin/pest --filter='describes behaviour'                 # focused
```

For Laravel: `php artisan test` wraps PHPUnit with framework-aware output.

## 5. Optional: security audit

```bash
composer audit 2>&1 | tail -10
```

Only run if the PR touches `composer.json` dependencies.

## Done?

Report completion only after syntax, style, static analysis (if configured), and tests pass. Do not suppress PHPStan errors with `@phpstan-ignore-line` without a comment explaining why.
