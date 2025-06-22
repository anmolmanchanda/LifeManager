# Roadmap ↔ Code Traceability Maintenance Guide

> **Purpose**: Quick reference for maintaining the roadmap traceability system
> **Target Audience**: Developers, maintainers, and contributors
> **Last Updated**: June 14, 2025

## 🔄 Regular Maintenance Tasks

### After Each Feature Implementation

1. **Update Feature Matrix** (`doc/feature_matrix.md`)
   - Change status from ❌ or ⏳ to ✅
   - Add actual file references if they differ from planned
   - Update notes with any implementation details

2. **Update README Roadmap**
   - Check the appropriate checkbox `- [x]`
   - Verify file references are correct
   - Update any status notes

3. **Update Implementation Tracking** (`doc/implementation_tracking.md`)
   - Update completion percentages
   - Add new lines of code counts
   - Update "Last Updated" dates

4. **Update File Headers**
   - Add roadmap reference to new files
   - Update status from ⏳ to ✅ in existing files
   - Update "Last Updated" timestamp

### Weekly Reviews

1. **Verify Documentation Accuracy**
   - Check that all file references are valid
   - Ensure completion percentages are accurate
   - Update any changed file locations

2. **Update Metrics**
   - Recalculate lines of code if significant changes
   - Update development velocity metrics
   - Review and update technical debt items

### Before Each Release

1. **Complete Documentation Audit**
   - Verify all features are properly documented
   - Check all file references are current
   - Update version completion percentages

2. **Create Version Tags**
   - Tag the release in git
   - Update "Status: SHIPPED" in documentation
   - Archive completed version documentation

---

## 📝 Documentation Templates

### File Header Template
```swift
//
// [FileName].swift
// LifeManager
//
// Implements: v[X.X] "[Feature Name]", v[Y.Y] "[Other Feature]"
// Roadmap Reference: v[X.X] [Version Name], v[Y.Y] [Other Version]
// Status: ✅ COMPLETE as of [Date] / ⏳ IN PROGRESS / ❌ NOT STARTED
// Future: v[Z.Z] [Planned Enhancement]
//
```

### Feature Matrix Entry Template
```markdown
| Feature Name | ✅/⏳/❌ | `Path/To/File.swift` | Implementation notes |
```

### Implementation Tracking Entry Template
```markdown
| Feature Name | ✅/⏳/❌ | `Primary/File.swift` | 123 | June XX, 2025 |
```

---

## 🎯 Status Icon Guidelines

### Primary Status Icons
- ✅ **Complete**: Feature fully implemented and tested
- ⏳ **In Progress**: Feature partially implemented or stub exists  
- ❌ **Not Started**: Feature not yet implemented
- 🔄 **Refactoring**: Feature exists but being improved/restructured

### Secondary Status Icons
- 🚀 **Shipped**: Version has been released
- 📋 **Planned**: Feature is planned for future version
- 🔧 **Technical Debt**: Known issue that needs addressing
- 📊 **Metrics**: Quantitative measurement or analysis

---

## 📁 File Organization Standards

### Documentation Structure
```
doc/
├── feature_matrix.md           # Main roadmap ↔ code mapping
├── implementation_tracking.md  # Detailed metrics and analysis  
├── traceability_maintenance.md # This maintenance guide
└── [future docs]/              # Additional documentation
```

### File Reference Format
- Use backticks for all file references: `Path/To/File.swift`
- Use relative paths from project root
- Include line numbers for specific implementations: `File.swift (lines 100-200)`
- Use directory references for multiple files: `Views/Calendar/` (9 files)

---

## 🔍 Quality Checks

### Before Committing Changes

- [ ] All file references are valid and current
- [ ] Status icons are consistent across all documents
- [ ] Completion percentages add up correctly
- [ ] All new files have proper header documentation
- [ ] Implementation details are logged in `implementation_details.txt`

### Monthly Audits

- [ ] Verify all features marked as ✅ are actually complete
- [ ] Check for any "phantom features" (marked complete but not implemented)
- [ ] Update technical debt analysis
- [ ] Review and update development velocity metrics
- [ ] Validate all documentation links and references

---

## 🚨 Common Issues & Solutions

### Issue: File References Become Invalid
**Solution**: Use relative paths and update references when files are moved

### Issue: Completion Percentages Don't Match
**Solution**: Recount features and verify calculations in implementation tracking

### Issue: Status Icons Inconsistent
**Solution**: Use the standard icon set defined in this guide

### Issue: Header Documentation Missing
**Solution**: Use the template above and add to all new files

### Issue: Technical Debt Not Tracked
**Solution**: Add items to implementation tracking document with priority levels

---

## 🎯 Best Practices

### Documentation
1. **Be Honest**: Mark features as incomplete if they're not fully implemented
2. **Be Specific**: Include exact file paths and line numbers when helpful
3. **Be Current**: Update documentation immediately after changes
4. **Be Consistent**: Use the same format and icons across all documents

### File Management
1. **Modular Documentation**: Keep documents focused and under 500 lines
2. **Clear Naming**: Use descriptive file names that indicate purpose
3. **Logical Organization**: Group related documentation together
4. **Version Control**: Track all documentation changes in git

### Maintenance
1. **Regular Updates**: Don't let documentation fall behind code
2. **Automated Checks**: Consider scripts to validate file references
3. **Team Communication**: Ensure all contributors understand the system
4. **Continuous Improvement**: Refine the system based on usage patterns

---

## 📞 Support & Questions

For questions about maintaining this traceability system:

1. **Check this guide first** for common issues and solutions
2. **Review existing documentation** for examples and patterns
3. **Follow the templates** provided for consistency
4. **Update this guide** if you discover new patterns or issues

---

*This maintenance guide should be updated whenever the traceability system is modified or improved.* 