---
description: "Writing JVM tests: JUnit 5 (Java + Kotlin), Kotest (Kotlin-native specs), Mockito / MockK for mocking, parameterized tests, and focused `./gradlew test` / `mvn test` runs. Covers both Gradle and Maven projects."
---

# JVM Testing (JUnit 5 + Kotest)

For new tests, use **JUnit 5 (Jupiter)** — it works for both Java and Kotlin and is the default across current Gradle/Maven templates. Kotlin projects can additionally use **Kotest** for BDD-style specs; the two coexist.

## JUnit 5 — Java

```java
import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.assertj.core.api.Assertions.assertThat;  // AssertJ is much nicer

@DisplayName("Authentication service")
class AuthServiceTest {

    private AuthService svc;

    @BeforeEach
    void setUp() { svc = new AuthService(new InMemoryUserStore()); }

    @Test
    @DisplayName("succeeds with valid credentials")
    void loginSucceeds() {
        var result = svc.login("test", "correct");
        assertThat(result.isAuthenticated()).isTrue();
    }

    @Test
    void loginFails() {
        assertThrows(AuthException.class,
                     () -> svc.login("test", "wrong"));
    }
}
```

## JUnit 5 — Kotlin

```kotlin
import org.junit.jupiter.api.*
import org.assertj.core.api.Assertions.assertThat

class AuthServiceTest {

    private lateinit var svc: AuthService

    @BeforeEach
    fun setUp() { svc = AuthService(InMemoryUserStore()) }

    @Test
    fun `login succeeds with valid credentials`() {
        val result = svc.login("test", "correct")
        assertThat(result.isAuthenticated).isTrue()
    }

    @Test
    fun `login fails with wrong password`() {
        assertThrows<AuthException> { svc.login("test", "wrong") }
    }
}
```

Backtick-quoted method names work in Kotlin test source — they produce readable reports and removing `@DisplayName`.

## Parameterized tests

```java
@ParameterizedTest
@CsvSource({
    "valid@email.com, true",
    "notanemail,      false",
    "@missing.com,    false",
})
void validatesEmail(String email, boolean expected) {
    assertThat(validateEmail(email)).isEqualTo(expected);
}
```

Kotlin equivalent uses `@ParameterizedTest` + `@CsvSource` the same way.

## Mocking — Mockito (Java/Kotlin) or MockK (Kotlin)

### Mockito

```java
@ExtendWith(MockitoExtension.class)
class CheckoutServiceTest {

    @Mock PaymentGateway gateway;
    @InjectMocks CheckoutService svc;

    @Test
    void charges_the_gateway() {
        when(gateway.charge(anyDouble())).thenReturn(new Receipt("ok"));
        svc.process(new Order(99.00));
        verify(gateway).charge(99.00);
    }
}
```

### MockK (Kotlin-friendlier)

```kotlin
class CheckoutServiceTest {
    private val gateway = mockk<PaymentGateway>()
    private val svc = CheckoutService(gateway)

    @Test
    fun `charges the gateway`() {
        every { gateway.charge(any()) } returns Receipt("ok")
        svc.process(Order(99.00))
        verify { gateway.charge(99.00) }
    }
}
```

MockK handles Kotlin's `final`-by-default classes and coroutines natively. Prefer it for Kotlin code; Mockito works but fights the language.

## Kotest (Kotlin-only)

```kotlin
import io.kotest.core.spec.style.StringSpec
import io.kotest.matchers.shouldBe
import io.kotest.assertions.throwables.shouldThrow

class AuthServiceSpec : StringSpec({
    val svc = AuthService(InMemoryUserStore())

    "login succeeds with valid credentials" {
        svc.login("test", "correct").isAuthenticated shouldBe true
    }

    "login fails with wrong password" {
        shouldThrow<AuthException> { svc.login("test", "wrong") }
    }
})
```

Kotest offers five spec styles (`StringSpec`, `FunSpec`, `DescribeSpec`, `BehaviorSpec`, `WordSpec`). Pick one per project and stick to it.

## Coroutines

```kotlin
// kotlinx-coroutines-test + JUnit 5
@Test
fun `async fetch`() = runTest {
    val result = withContext(Dispatchers.Default) { asyncFetch() }
    assertThat(result).isNotNull
}
```

Do not use `runBlocking` in tests — `runTest` provides a virtual-time scheduler and keeps suspending tests fast.

## Integration tests — Testcontainers

```kotlin
@Testcontainers
class PostgresRepoTest {
    @Container
    val postgres = PostgreSQLContainer<Nothing>("postgres:16-alpine")

    @Test
    fun `round-trip`() {
        val repo = PostgresRepo(postgres.jdbcUrl, postgres.username, postgres.password)
        repo.insert(User("alice"))
        assertThat(repo.find("alice")).isNotNull
    }
}
```

Testcontainers works the same from Java and Kotlin. It needs Docker available on the host — flag if CI doesn't provide it.

## Focused test runs

### Gradle

```bash
./gradlew test                                          # full suite
./gradlew test --tests 'com.example.AuthServiceTest'     # one class
./gradlew test --tests '*.AuthServiceTest.loginSucceeds' # one method
./gradlew :module:test --tests '*.FooTest'               # one module in multi-module
./gradlew test --rerun-tasks                             # skip Gradle caching
```

### Maven

```bash
mvn test                                                 # full
mvn test -Dtest=AuthServiceTest                          # one class
mvn test -Dtest=AuthServiceTest#loginSucceeds            # one method
```

## Test fixtures and directory layout

Gradle: `src/test/java/` + `src/test/kotlin/` + `src/test/resources/`. Maven: same.

For test-only code shared across classes (builders, in-memory fakes), put it in the same `src/test/` tree. For sharing across modules, set up a `test-fixtures` source set (Gradle) or a separate `-test` jar (Maven).

## Coverage

See `coverage-audit` for JaCoCo / Kover invocation and thresholds.
