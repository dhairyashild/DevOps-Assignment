# Branching Strategy

## Branch Types
- `main` - Production ready code
- `develop` - Development integration
- `feature/*` - New features
- `hotfix/*` - Critical production fixes

## Workflow Rules
1. Always create feature branches from `develop`
2. PR required for all merges
3. Minimum 1 code review approval required
4. All tests must pass in CI
5. Use conventional commit messages

## Commit Message Format
```
feat: add user authentication
fix: resolve database connection issue
docs: update API documentation
test: add unit tests for auth service
chore: update dependencies
```

## Branch Naming Convention
- Features: `feature/user-auth`, `feature/payment-integration`
- Hotfixes: `hotfix/critical-bug`, `hotfix/security-patch`
