# Rules
- **Handle API errors gracefully**, providing user-friendly messages.
- Use `throws` for **recoverable errors**, `Result<T, Error>` for complex operations, and `try?` for optional failures.
- Use **OSLog** for structured logging.
- Avoid exposing **raw error details** to users.
- Implement logging for **critical failures**.