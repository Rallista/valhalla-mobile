# Valhalla Android Documentation

This directory contains documentation for the Valhalla Android library using Dokka, Kotlin's documentation engine.

## Overview

The documentation is structured similar to Apple's DocC:
- **Valhalla.md**: Main documentation file with overview, getting started guide, and usage examples
- **KDoc comments**: Inline documentation in Kotlin source files

## Generating Documentation

### Prerequisites

Ensure you have the Dokka plugin configured in your `build.gradle.kts`:

```kotlin
plugins {
    alias(libs.plugins.dokka)
}
```

### Generate HTML Documentation

To generate the documentation in HTML format, run:

```bash
./gradlew dokkaHtml
```

The generated documentation will be available at:
```
android/valhalla/build/dokka/html/index.html
```

### Generate Other Formats

Dokka supports multiple output formats:

```bash
# Generate Javadoc-style HTML
./gradlew dokkaJavadoc

# Generate GFM (GitHub Flavored Markdown)
./gradlew dokkaGfm
```

## Documentation Structure

### Main Documentation (Valhalla.md)

The `Valhalla.md` file serves as the landing page for the documentation and includes:

- **Overview**: Introduction to the library
- **Getting Started**: Setup instructions and requirements
- **Usage**: Code examples and common patterns
- **Android-Specific Considerations**: Platform-specific guidance
- **Architecture**: High-level design overview
- **Topics**: Organized list of key classes and concepts

### KDoc Comments

Source code documentation follows KDoc conventions:

```kotlin
/**
 * Brief description of the class or function.
 *
 * More detailed explanation of what it does and how to use it.
 *
 * @param paramName Description of the parameter.
 * @return Description of the return value.
 * @throws ExceptionType When this exception is thrown.
 * @see RelatedClass
 */
```

### Documentation Guidelines

When adding documentation:

1. **Brief descriptions**: Keep the first line concise and descriptive
2. **Parameters**: Document all parameters with `@param`
3. **Return values**: Use `@return` for non-void functions
4. **Exceptions**: Document thrown exceptions with `@throws`
5. **References**: Link related classes with `@see`
6. **Code samples**: Place in `Valhalla.md`, not in KDoc (to avoid duplication)

## Viewing the Documentation

After generating the documentation:

1. Navigate to `android/valhalla/build/dokka/html/`
2. Open `index.html` in your web browser
3. Browse the documentation and API reference

## Publishing Documentation

The documentation can be:

- **Hosted on GitHub Pages**: Push the `build/dokka/html` directory to a `gh-pages` branch
- **Included in releases**: Package the HTML docs with release artifacts
- **Served locally**: Use a simple HTTP server for local development

## Resources

- [Dokka Documentation](https://kotlinlang.org/docs/dokka-introduction.html)
- [KDoc Syntax](https://kotlinlang.org/docs/kotlin-doc.html)
- [Valhalla API Reference](https://valhalla.github.io/valhalla/)