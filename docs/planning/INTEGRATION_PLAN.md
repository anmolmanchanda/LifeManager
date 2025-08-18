# Feature Integration Plan - v2.0 Recovery

## Overview
This document outlines the systematic integration of Enhanced PARA features from the broken commit (`82578ec`) into the stable base (`v1.9.1-stable`).

## Integration Priority Queue

### 🔴 High Priority (Core Features)
These features provide immediate value and should be integrated first.

#### 1. Dynamic Context Window ⏱️ 2-3 hours
- [ ] Extract dynamic window logic from `ContextMemoryService.swift`
- [ ] Remove calendar dependencies initially
- [ ] Test with 50-100 item window sizing
- [ ] Verify memory management

#### 2. Enhanced Semantic Embeddings ⏱️ 3-4 hours
- [ ] Port domain-specific PARA weighting from `EmbeddingsService.swift`
- [ ] Test similarity calculations
- [ ] Verify 82% accuracy claim
- [ ] Ensure backward compatibility

#### 3. Personal Rules Learning ⏱️ 4-5 hours
- [ ] Extract learning logic from `PersonalRulesService.swift`
- [ ] Implement correction tracking
- [ ] Test rule application
- [ ] Verify self-improvement metrics

### 🟡 Medium Priority (Enhancement Features)
These features enhance user experience but aren't critical.

#### 4. Advanced Analytics Service ⏱️ 3-4 hours
- [ ] Review `AdvancedAnalyticsService.swift` (891 lines)
- [ ] Extract productivity patterns
- [ ] Implement visualization basics
- [ ] Test performance impact

#### 5. Calendar Integration for PARA ⏱️ 2-3 hours
- [ ] Extract scheduling context from broken commit
- [ ] Integrate with existing calendar service
- [ ] Test time slot analysis
- [ ] Verify no conflicts

#### 6. Clarification Questions System ⏱️ 2-3 hours
- [ ] Port 6 uncertainty types
- [ ] Implement UI for questions
- [ ] Test user interaction flow
- [ ] Measure effectiveness

### 🟢 Low Priority (Future Features)
These can wait for v2.1 or later releases.

#### 7. MCP Integration ⏱️ 1-2 days
- [ ] Evaluate 9 server setup
- [ ] Test prompt caching benefits
- [ ] Measure token cost savings
- [ ] Document configuration

#### 8. Decision Tree Reasoning ⏱️ 1 day
- [ ] Extract reasoning logic
- [ ] Implement visualization
- [ ] Test accuracy improvements

#### 9. Productivity Visualization ⏱️ 1 day
- [ ] Design dashboard UI
- [ ] Implement charts
- [ ] Add export functionality

## Integration Process

### For Each Feature:

1. **Preparation** (30 mins)
   ```bash
   git checkout feature/integrate-enhanced-para
   git pull origin recovery/stable-build
   ```

2. **Extraction** (varies)
   ```bash
   # Review the feature in broken commit
   git show 82578ec -- path/to/file.swift
   
   # Cherry-pick specific changes
   git checkout 82578ec -- path/to/specific/file.swift
   
   # Or manually copy relevant code sections
   ```

3. **Testing** (1 hour minimum)
   ```bash
   # Build test
   swift build --configuration release
   
   # Run tests
   swift test
   
   # Manual testing
   ./build_and_install.sh
   ```

4. **Commit** (15 mins)
   ```bash
   # Stage changes selectively
   git add -p
   
   # Commit with clear message
   git commit -m "feat(component): add specific feature
   
   - Extract from enhanced PARA system
   - Test coverage: XX%
   - Performance impact: minimal"
   ```

5. **Documentation** (30 mins)
   - Update CHANGELOG.md
   - Update feature documentation
   - Add to user guide if needed

## Success Criteria

### Per Feature:
- ✅ Builds without errors
- ✅ Existing tests pass
- ✅ New tests added (if applicable)
- ✅ Performance acceptable (<100ms impact)
- ✅ Memory usage stable
- ✅ UI responsive
- ✅ Documentation updated

### Overall:
- ✅ All high-priority features integrated
- ✅ No regression in existing features
- ✅ User experience improved
- ✅ System stability maintained

## Risk Mitigation

### Before Integration:
1. Create backup branch
2. Document current state
3. Review dependencies

### During Integration:
1. Test after each change
2. Commit frequently
3. Monitor performance

### After Integration:
1. Run full test suite
2. Manual regression testing
3. User acceptance testing

## Timeline

### Week 1 (Current)
- Day 1-2: High Priority features 1-2
- Day 3-4: High Priority feature 3
- Day 5: Testing and stabilization

### Week 2
- Day 1-2: Medium Priority features 4-5
- Day 3: Medium Priority feature 6
- Day 4-5: Integration testing

### Week 3+ (Optional)
- Low Priority features as time permits
- Performance optimization
- User feedback incorporation

## Rollback Plan

If integration causes issues:

1. **Immediate**: 
   ```bash
   git checkout v1.9.1-stable
   ./build_and_install.sh
   ```

2. **Partial Rollback**:
   ```bash
   git revert <problematic-commit>
   ```

3. **Complete Reset**:
   ```bash
   git reset --hard v1.9.1-stable
   git push --force-with-lease
   ```

## Notes

- Each feature should be tested in isolation first
- Consider feature flags for risky integrations
- Keep commits atomic and focused
- Document any deviations from this plan

## Status Tracking

Update this section as features are integrated:

| Feature | Status | Branch | Commit | Notes |
|---------|--------|--------|--------|-------|
| Dynamic Context Window | 🔜 Planned | - | - | - |
| Enhanced Embeddings | 🔜 Planned | - | - | - |
| Personal Rules | 🔜 Planned | - | - | - |
| Analytics Service | 🔜 Planned | - | - | - |
| Calendar Integration | 🔜 Planned | - | - | - |
| Clarification Questions | 🔜 Planned | - | - | - |

---

*Last Updated: January 17, 2025*
*Recovery Version: v1.9.1-stable*
*Target Version: v2.0*