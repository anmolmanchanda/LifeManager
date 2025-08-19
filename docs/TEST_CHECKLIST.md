# LifeManager v1.9.1 Test Checklist

## Pre-Testing Setup
- [ ] Build app with `./build_and_install.sh`
- [ ] Verify app launches without errors
- [ ] Check logs with `./monitor_logs.sh -f`
- [ ] Ensure database connection works

## Core PARA Operations

### 1. Brain Dump Processing
- [ ] Paste simple text → verify blob creation
- [ ] Paste multi-line text → verify parsing
- [ ] Process with AI → verify categorization
- [ ] Check task extraction works
- [ ] Verify priority assignment

### 2. Projects Management
- [ ] Create new project
- [ ] Edit project details
- [ ] Move items to project
- [ ] Archive project
- [ ] Delete project

### 3. Areas Management
- [ ] Create new area
- [ ] Assign items to area
- [ ] Edit area properties
- [ ] View area contents

### 4. Resources Management
- [ ] Add new resource
- [ ] Tag resources
- [ ] Search resources
- [ ] Link to projects/areas

### 5. Archives
- [ ] Archive items
- [ ] View archived content
- [ ] Restore from archive
- [ ] Permanent deletion

## Calendar Integration

### 1. Basic Calendar
- [ ] View calendar grid
- [ ] Navigate months
- [ ] Switch views (day/week/month)
- [ ] Today button works

### 2. Event Management
- [ ] Create event via drag
- [ ] Edit event details
- [ ] Delete event
- [ ] Move event (drag & drop)

### 3. Task Scheduling
- [ ] Schedule task to calendar
- [ ] View task on calendar
- [ ] Complete calendar task
- [ ] Reschedule task

### 4. Parking Lot
- [ ] View unscheduled tasks
- [ ] Drag task to calendar
- [ ] Filter parking lot items
- [ ] Clear completed items

## AI Features

### 1. LLM Processing
- [ ] API key configured
- [ ] Brain dump processing works
- [ ] Task extraction accurate
- [ ] Priority assignment logical
- [ ] Error handling for API failures

### 2. Embeddings
- [ ] Generate embeddings for new items
- [ ] Semantic search works
- [ ] Similar items suggested
- [ ] Performance acceptable

### 3. Categorization
- [ ] Auto-categorization works
- [ ] Confidence scores shown
- [ ] Manual override possible
- [ ] Learning from corrections

## User Interface

### 1. Navigation
- [ ] Main menu works
- [ ] View switching smooth
- [ ] Back/forward navigation
- [ ] Keyboard shortcuts work

### 2. Data Entry
- [ ] Text input works
- [ ] Paste functionality
- [ ] Form validation
- [ ] Error messages clear

### 3. Visual Feedback
- [ ] Loading indicators shown
- [ ] Success messages appear
- [ ] Error states handled
- [ ] Progress bars accurate

## Data Management

### 1. Persistence
- [ ] Data saves to database
- [ ] Changes persist on restart
- [ ] No data loss on crash
- [ ] Backup/restore works

### 2. Sync
- [ ] Real-time updates work
- [ ] Multi-window sync
- [ ] Conflict resolution
- [ ] Offline mode graceful

### 3. Search
- [ ] Global search works
- [ ] Filter by type
- [ ] Filter by date
- [ ] Search results accurate

## Performance

### 1. Speed
- [ ] App launches < 3 seconds
- [ ] View switches < 500ms
- [ ] Search results < 1 second
- [ ] AI processing < 5 seconds

### 2. Memory
- [ ] No memory leaks
- [ ] Stable memory usage
- [ ] Large data sets handled
- [ ] Cleanup on view changes

### 3. Stability
- [ ] No crashes in normal use
- [ ] Error recovery works
- [ ] Network failures handled
- [ ] Database errors managed

## Edge Cases

### 1. Empty States
- [ ] Empty inbox handled
- [ ] No projects state
- [ ] No calendar events
- [ ] First-time user experience

### 2. Large Data
- [ ] 1000+ items perform well
- [ ] Long text handled
- [ ] Many calendar events
- [ ] Search still fast

### 3. Error Conditions
- [ ] No network handled
- [ ] API key invalid
- [ ] Database offline
- [ ] Disk full scenario

## Regression Tests

### From v1.9.0
- [ ] Basic PARA operations
- [ ] Calendar functionality
- [ ] AI categorization
- [ ] UI responsiveness

### Fixed Issues
- [ ] PARACategory field issue resolved
- [ ] Build completes successfully
- [ ] No compilation warnings critical
- [ ] Tests can run (even if failing)

## Sign-off

### Test Environment
- **macOS Version:** ___________
- **Build Number:** ___________
- **Test Date:** ___________
- **Tester:** ___________

### Results Summary
- **Passed:** ___/___
- **Failed:** ___/___
- **Blocked:** ___/___
- **Notes:** ___________

### Approval
- [ ] All critical tests passed
- [ ] No blocking issues found
- [ ] Performance acceptable
- [ ] Ready for release

---

*Use this checklist for each release candidate testing cycle*