---
description: "Writing and running Rust tests: async tests with tokio, tempfile for fixtures, mockall for traits, and focused cargo test runs"
---

# Rust Testing

## Test module convention

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_something() { ... }

    #[tokio::test]
    async fn test_async_thing() { ... }
}
```

## Async tests

If the crate uses Tokio, use `#[tokio::test]` for async test functions rather than `#[test]` with a manually built runtime. Use `#[tokio::test(flavor = "multi_thread")]` when the code under test spawns tasks that must actually run in parallel.

```rust
#[tokio::test]
async fn test_async_operation() {
    // works with async/await directly
}
```

For `async-std` or `smol`, use their respective `#[async_std::test]` / `#[smol_potat::test]` attributes.

## Temp directories (integration tests)

```rust
use tempfile::TempDir;

let tmp = TempDir::new().unwrap();
let root = tmp.path();
// TempDir cleans up automatically on drop
```

## Mocking with mockall

```rust
use mockall::automock;

#[automock]
trait MyTrait { fn do_thing(&self) -> String; }

let mut mock = MockMyTrait::new();
mock.expect_do_thing().returning(|| "result".into());
```

## Running tests

```bash
# All tests
cargo test

# One test by exact name
cargo test test_name -- --nocapture

# All tests in a module
cargo test my_module::submodule

# One crate in a workspace
cargo test -p <crate-name>

# Show output even for passing tests
cargo test -- --nocapture

# Run ignored tests
cargo test -- --ignored
```

## Conditional compilation

Gate platform-specific tests so they don't break CI on other OSes:

```rust
#[cfg(unix)]
#[test]
fn test_unix_socket() { ... }

#[cfg(target_os = "macos")]
#[test]
fn test_macos_specific() { ... }
```

## Docker-backed integration tests

For tests that need real infrastructure (databases, message queues), the `testcontainers` crate spins up throwaway Docker containers. Only reach for it when a mock won't do — it requires Docker running locally and slows the suite down significantly. Gate with `#[ignore]` or a feature flag if you want regular `cargo test` to skip it.
