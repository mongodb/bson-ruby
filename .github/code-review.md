# Code Reviews

When reviewing code, focus on:

## Security Critical Issues
- Check for hardcoded secrets, API keys, or credentials
- Check for instances of potential method call injection, dynamic code execution, symbol injection or other code injection vulnerabilities.

## Performance Red Flags
- Spot inefficient loops and algorithmic issues.
- Check for memory leaks and resource cleanup.

## Code Quality Essentials
- Methods should be focused and appropriately sized. If a method is doing too much, suggest refactorings to split it up.
- Use clear, descriptive naming conventions.
- Avoid encapsulation violations and ensure proper separation of concerns.
- All public classes, modules, and methods should have clear documentation in YARD format.
- If `method_missing` is implemented, ensure that `respond_to_missing?` is also implemented.
- Rubocop is used by this project to enforce code style. Always refer to the project's .rubocop.yml file for guidance on the project's style preferences.

## BSON-specific Concerns
- This library includes C native extensions. When reviewing changes to serialization or deserialization, verify that both the Ruby and C implementations remain consistent.
- Look for potential issues with binary data handling: endianness, buffer overflows, encoding mismatches.
- BSON types must conform to the BSON specification. Verify that type IDs, serialization formats, and edge cases match the spec.

## Review Style
- Be specific and actionable in feedback
- Explain the "why" behind recommendations
- Acknowledge good patterns when you see them
- Ask clarifying questions when code intent is unclear
- When possible, suggest that the pull request be labeled as a `bug`, a `feature`, or a `bcbreak` (a "backwards-compatibility break").
- PR's with no user-visible effect do not need to be labeled.
- Do not review or suggest changes to YAML files under the `spec/spec_tests/data/` directory; these are test fixtures shared between all BSON implementations and are not owned by this repository.

Always prioritize security vulnerabilities and performance issues that could impact users.

Always suggest changes to improve readability and testability.

When reviewing code, be encouraging.
