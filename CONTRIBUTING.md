# Contributing to LifeManager

**Enterprise-Grade Development Guidelines**

## 🚨 MANDATORY READING

Before contributing, you **MUST** read and follow our [Development Standards](./DEVELOPMENT_STANDARDS.md). This project operates under enterprise-grade practices with zero tolerance for substandard code.

## 🔄 Development Workflow

### 1. Setting Up Development Environment

```bash
# Clone repository
git clone https://github.com/anmolmanchanda/LifeManager.git
cd LifeManager

# Install pre-commit hooks (MANDATORY)
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Install dependencies
swift package resolve

# Verify setup
swift build
swift test --parallel
```

### 2. Feature Development Process

**EVERY feature must follow this exact process:**

```bash
# 1. Start from latest dev
git checkout dev
git pull origin dev

# 2. Create feature branch (MANDATORY naming convention)
git checkout -b feature/JIRA-XXX-descriptive-name

# 3. Develop with commits every 2 hours maximum
git add .
git commit -m "feat(component): implement feature description"

# 4. Run quality checks before push
swift test --parallel
swiftlint lint --strict
swift build --configuration release

# 5. Push feature branch
git push origin feature/JIRA-XXX-descriptive-name

# 6. Create Pull Request to dev branch
# 7. Wait for 2 approvals minimum
# 8. Squash merge to dev
```

### 3. Branch Protection Rules

**Protected Branches:**
- `main`: Production releases only (2 approvals required)
- `dev`: Integration branch (1 approval required)

**Forbidden Actions:**
- ❌ Direct commits to main/dev
- ❌ Force pushing to protected branches
- ❌ Merging without approval
- ❌ Bypassing CI checks

## 📝 Commit Message Standards

**MANDATORY: Use Conventional Commits**

```bash
feat(auth): implement OAuth2 authentication flow
fix(calendar): resolve timezone calculation bug
docs(api): update endpoint documentation
test(tasks): add comprehensive unit tests
refactor(ui): optimize component rendering performance
perf(db): improve query execution time
chore(deps): update dependencies to latest versions
```

**Format Requirements:**
- Type: `feat|fix|docs|style|refactor|test|chore`
- Scope: Component or module affected
- Description: Present tense, imperative mood
- Maximum 72 characters for summary line

## 🧪 Testing Requirements

**MANDATORY Test Coverage:**
- **Unit Tests**: 90% minimum coverage
- **Integration Tests**: All service interactions
- **UI Tests**: Critical user workflows
- **Performance Tests**: API response times

```bash
# Run all tests
swift test --parallel

# Run specific test suite
swift test --filter LifeManagerTests

# Generate coverage report
swift test --enable-code-coverage
```

**Test Naming Convention:**
```swift
func test_methodName_givenCondition_shouldExpectedBehavior() {
    // Test implementation
}
```

## 📚 Documentation Requirements

**MANDATORY Documentation:**
- All public APIs must have complete documentation
- Complex algorithms require explanation comments
- Architecture decisions need ADRs (Architecture Decision Records)
- README updates for new features

```swift
/// Processes task with intelligent prioritization
/// - Parameter task: The task to process (must be valid)
/// - Returns: Processing result with confidence score
/// - Throws: ProcessingError if validation fails
/// - Note: This is a critical path function
/// - Since: v2.3.0
func processTask(_ task: LifeTask) throws -> ProcessingResult
```

## 🔍 Code Review Process

**Review Requirements:**
- **2 approvals** for main branch PRs
- **1 approval** for dev branch PRs
- **All CI checks** must pass
- **Performance impact** must be assessed
- **Security implications** must be reviewed

**Review Checklist:**
- [ ] Code follows Swift style guidelines
- [ ] Tests are comprehensive and pass
- [ ] Documentation is complete
- [ ] Performance is acceptable
- [ ] Security best practices followed
- [ ] No breaking changes without migration plan

## 🚀 Release Process

### Version Management
- **Semantic Versioning**: MAJOR.MINOR.PATCH
- **Release Branches**: `release/vX.Y.Z`
- **Hotfix Branches**: `hotfix/vX.Y.Z-description`

### Release Checklist
- [ ] All tests pass in staging
- [ ] Performance benchmarks met
- [ ] Security scan clean
- [ ] Documentation updated
- [ ] Migration scripts ready (if needed)
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured

## 🔐 Security Guidelines

**MANDATORY Security Practices:**
- Never commit secrets or API keys
- All user inputs must be validated
- Use secure coding practices
- Follow OWASP guidelines
- Regular dependency updates

```bash
# Check for secrets before commit
git diff --cached | grep -E "(api_key|password|secret|token)"

# Audit dependencies
swift package audit
```

## 📊 Quality Gates

**Automated Checks (CI/CD):**
- ✅ Swift compilation
- ✅ Unit tests (90% coverage)
- ✅ SwiftLint compliance
- ✅ Security scan
- ✅ Performance benchmarks
- ✅ Documentation generation

**Manual Checks:**
- ✅ Code review approval
- ✅ QA testing in staging
- ✅ Performance validation
- ✅ Security assessment

## 🛠️ Development Tools

**Required Tools:**
- Xcode 15.0+
- SwiftLint
- SwiftFormat
- Git 2.30+

**Recommended Tools:**
- Sourcetree or GitKraken
- Charles Proxy for debugging
- Instruments for performance profiling

## ❌ Common Mistakes to Avoid

**NEVER:**
- Commit directly to main or dev branches
- Skip tests or reduce coverage
- Leave TODOs without JIRA tickets
- Use print statements instead of Logger
- Force unwrap optionals unnecessarily
- Ignore SwiftLint warnings
- Commit large files without Git LFS
- Include secrets in code

## 🆘 Getting Help

**Resources:**
- [Development Standards](./DEVELOPMENT_STANDARDS.md)
- [Architecture Documentation](./docs/architecture/)
- [API Documentation](./docs/api/)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)

**Contacts:**
- Technical questions: Create GitHub issue
- Process questions: Team lead
- Security concerns: Security team

## 📋 Issue Templates

**Bug Report Template:**
```markdown
## Bug Description
Brief description of the issue

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: macOS version
- Swift version
- App version

## Additional Context
Any other relevant information
```

**Feature Request Template:**
```markdown
## Feature Description
Brief description of the requested feature

## Business Justification
Why this feature is needed

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Considerations
Any technical constraints or dependencies

## Definition of Done
What constitutes completion of this feature
```

## 🏆 Recognition

**Contribution Recognition:**
- Quality contributions are recognized in release notes
- Major contributions earn committer status
- Outstanding contributors become maintainers

**Quality Metrics:**
- Code quality score
- Test coverage contribution
- Documentation improvement
- Bug fix efficiency

---

**Remember: We're building enterprise-grade software. Every contribution matters and must meet our high standards.**

---

*Last Updated: January 2025*  
*Version: 1.0*