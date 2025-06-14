# LifeManager Troubleshooting Guide

## Known Issues and Solutions

### 🚨 Critical Issues (Currently Being Fixed)

#### 1. Drag & Drop Not Working
**Status**: Known Issue - Being Fixed
**Symptoms**: 
- Tasks cannot be dragged from parking lot to calendar
- Drop zones not responding to drag operations
- No visual feedback during drag operations

**Current Workarounds**:
- Use context menu "Quick Schedule" option
- Manually create events and link to tasks
- Use keyboard shortcuts for task scheduling

**Technical Details**:
- Gesture coordination conflicts between drag and context menu gestures
- Drop validation logic needs improvement
- State management issues with drag operations

#### 2. Context Menus Not Appearing
**Status**: Known Issue - Being Fixed
**Symptoms**:
- Right-click on calendar events shows no menu
- Right-click on parking lot tasks shows no menu
- Context menu actions not triggering

**Current Workarounds**:
- Use toolbar buttons for common actions
- Access task/event details through double-click
- Use keyboard shortcuts where available

**Technical Details**:
- Gesture conflicts with drag operations
- Context menu implementation needs gesture priority fixes
- SwiftUI context menu coordination issues

#### 3. Day View Schedule Starts at 6 AM
**Status**: Known Issue - Being Fixed
**Symptoms**:
- Day view calendar starts at 6:00 AM instead of midnight
- Early morning hours (00:00-06:00) not visible
- Cannot schedule tasks before 6 AM

**Current Workarounds**:
- Use week or month view for early morning scheduling
- Manually adjust event times in edit mode
- Schedule late night tasks as "next day" events

**Technical Details**:
- Calendar view configuration hardcoded to 6 AM start
- Need to update CalendarDayView to start at 00:00
- Time slot generation logic needs adjustment

## Authentication Issues

### Development Authentication Problems

#### Invalid Credentials Error
**Symptoms**: "Invalid credentials" when using test account
**Solution**:
1. Use the updated test account: `dev@lifemanager.local`
2. Try any password (system will create account if needed)
3. If still failing, click "Force Create Dev Account"

#### Magic Links Not Working
**Symptoms**: No email received, magic link doesn't work
**Solutions**:
1. **Primary**: Use "Force Create Dev Account" button
2. **Alternative**: Enable "Development Bypass" for immediate access
3. **Manual Processing**: Try manual callback processing if available

#### Development Bypass Shows No Content
**Symptoms**: Development bypass works but no data appears
**Solution**: 
- The system now creates real authenticated sessions
- Wait for initial data sync (may take 10-15 seconds)
- Check console logs for Supabase connection status

#### Account Creation Failures
**Symptoms**: Cannot create new accounts, signup fails
**Solutions**:
1. Use "Force Create Dev Account" - tries creation first, then signin
2. Check internet connection and Supabase status
3. Try different email format if using custom email
4. Clear browser cache if using web components

## Calendar System Issues

### Calendar Not Updating

#### Events Not Appearing
**Symptoms**: Scheduled events don't show in calendar views
**Solutions**:
1. **Force Refresh**: Use refresh button or Cmd+R
2. **Check View Mode**: Ensure you're in the correct view (day/week/month)
3. **Date Range**: Verify selected date range includes your events
4. **Real-time Sync**: Check Supabase connection status

#### Stale Data in Calendar
**Symptoms**: Old events still showing, new events missing
**Solutions**:
1. **Restart Application**: Close and reopen LifeManager
2. **Clear Cache**: Clear local cache and force reload
3. **Database Sync**: Check Supabase real-time subscriptions
4. **Network Issues**: Verify internet connection

### Toggl Integration Issues

#### API Rate Limiting (429 Errors)
**Symptoms**: "Too Many Requests" errors, failed API calls
**Solutions**:
1. **Wait Period**: Wait 3+ seconds between manual API calls
2. **Check Implementation**: Verify 3-second delays are working
3. **API Token**: Ensure valid Toggl API token is configured
4. **Workspace ID**: Verify correct workspace ID in configuration

#### Time Entries Not Syncing
**Symptoms**: Toggl time entries not appearing in calendar
**Solutions**:
1. **API Configuration**: Check Toggl API token and workspace ID
2. **Date Range**: Ensure date range covers your time entries
3. **Project Mapping**: Verify Toggl projects are mapped correctly
4. **Rate Limiting**: Check if rate limiting is causing sync delays

#### Auto-Bumping Not Working
**Symptoms**: Schedule conflicts not automatically resolved
**Solutions**:
1. **Enable Auto-Bumping**: Check if auto-bumping is enabled in settings
2. **Conflict Detection**: Verify conflict detection logic is working
3. **Buffer Settings**: Ensure buffer management is properly configured
4. **Real-time Data**: Check if Toggl data is updating in real-time

## Performance Issues

### Slow Application Performance

#### High Memory Usage
**Symptoms**: Application becomes slow, high memory consumption
**Solutions**:
1. **Restart Application**: Close and reopen LifeManager
2. **Reduce Data Load**: Limit date ranges in calendar views
3. **Clear Cache**: Clear cached data and temporary files
4. **System Resources**: Check available system memory

#### Slow Loading Times
**Symptoms**: Long delays when switching views or loading data
**Solutions**:
1. **Internet Connection**: Check network connectivity
2. **Supabase Status**: Verify Supabase service status
3. **Database Optimization**: Check for database performance issues
4. **Local Cache**: Clear and rebuild local cache

#### UI Responsiveness Issues
**Symptoms**: UI freezes, slow response to user interactions
**Solutions**:
1. **Background Processing**: Ensure heavy operations run in background
2. **SwiftUI Updates**: Check for excessive view updates
3. **Memory Leaks**: Look for retain cycles in ViewModels
4. **Thread Management**: Verify proper main thread usage

## Data Synchronization Issues

### Supabase Connection Problems

#### Connection Timeouts
**Symptoms**: "Connection timeout" errors, failed database operations
**Solutions**:
1. **Network Check**: Verify internet connection stability
2. **Supabase Status**: Check Supabase service status page
3. **Firewall Settings**: Ensure Supabase URLs aren't blocked
4. **Retry Logic**: Implement exponential backoff for retries

#### Real-time Subscription Failures
**Symptoms**: Data not updating in real-time, stale information
**Solutions**:
1. **Reconnection**: Force reconnect to Supabase real-time
2. **Subscription Status**: Check real-time subscription status
3. **Authentication**: Verify authenticated session is valid
4. **Channel Management**: Ensure proper channel subscription/unsubscription

### Data Consistency Issues

#### Duplicate Items
**Symptoms**: Same tasks/events appearing multiple times
**Solutions**:
1. **Deduplication**: Use search to identify and merge duplicates
2. **Sync Logic**: Check synchronization logic for race conditions
3. **UUID Conflicts**: Verify UUID generation is working correctly
4. **Database Constraints**: Ensure proper database constraints

#### Missing Data
**Symptoms**: Tasks, events, or content disappearing
**Solutions**:
1. **Archive Check**: Look in Archives section for moved items
2. **Soft Delete**: Check if items were soft-deleted (recoverable)
3. **Sync Status**: Verify data synchronization completed
4. **Backup Restore**: Restore from recent backup if available

## UI/UX Issues

### SwiftUI Rendering Problems

#### Layout Issues
**Symptoms**: UI elements overlapping, incorrect positioning
**Solutions**:
1. **Window Resize**: Try resizing the application window
2. **View Refresh**: Force refresh the problematic view
3. **SwiftUI Updates**: Check for SwiftUI state management issues
4. **Constraint Conflicts**: Look for layout constraint conflicts

#### Navigation Problems
**Symptoms**: Cannot navigate between views, stuck in one view
**Solutions**:
1. **Navigation Stack**: Check NavigationView/NavigationStack state
2. **View State**: Verify view state management is correct
3. **Memory Issues**: Check for memory-related navigation problems
4. **Restart Navigation**: Reset navigation state by restarting app

### Accessibility Issues

#### Keyboard Navigation
**Symptoms**: Cannot navigate using keyboard shortcuts
**Solutions**:
1. **Focus Management**: Ensure proper focus management
2. **Accessibility Labels**: Verify accessibility labels are set
3. **Keyboard Shortcuts**: Check keyboard shortcut implementations
4. **VoiceOver Support**: Test with VoiceOver if needed

## API Integration Issues

### OpenAI/LLM Service Problems

#### API Key Issues
**Symptoms**: "Invalid API key" errors, LLM processing fails
**Solutions**:
1. **Key Validation**: Verify OpenAI API key is correct and active
2. **Key Format**: Ensure API key format is correct (starts with 'sk-')
3. **Billing Status**: Check OpenAI account billing status
4. **Rate Limits**: Verify you haven't exceeded API rate limits

#### Processing Failures
**Symptoms**: AI processing fails, no categorization results
**Solutions**:
1. **Content Length**: Check if content exceeds token limits
2. **Prompt Templates**: Verify prompt templates are valid
3. **Model Availability**: Ensure requested model (GPT-4) is available
4. **Network Issues**: Check network connectivity to OpenAI

### External Service Integration

#### Service Unavailability
**Symptoms**: External services (Toggl, OpenAI) not responding
**Solutions**:
1. **Service Status**: Check external service status pages
2. **Fallback Options**: Use fallback options when available
3. **Retry Logic**: Implement proper retry mechanisms
4. **Graceful Degradation**: Ensure app works without external services

## Debugging and Diagnostics

### Debug Logging

#### Enable Debug Logging
```swift
// Enable comprehensive logging
LifeLogger.setLogLevel(.debug)

// Specific subsystem logging
LifeLogger.calendar(.debug, "Calendar debug message")
LifeLogger.dragDrop(.info, "Drag drop operation")
LifeLogger.toggl(.warning, "Toggl API warning")
```

#### Log Analysis
1. **Console Output**: Check Xcode console for error messages
2. **Log Files**: Look for log files in application support directory
3. **Error Patterns**: Identify recurring error patterns
4. **Performance Metrics**: Monitor performance-related logs

### System Information

#### Environment Check
- **macOS Version**: Ensure compatible macOS version
- **Swift Version**: Verify Swift/SwiftUI compatibility
- **Memory Available**: Check available system memory
- **Network Status**: Verify network connectivity

#### Application State
- **Authentication Status**: Check if properly authenticated
- **Database Connection**: Verify Supabase connection
- **Service Status**: Check external service connections
- **Cache Status**: Verify cache state and size

## Recovery Procedures

### Data Recovery

#### Backup Restoration
1. **Locate Backups**: Find recent backup files
2. **Verify Integrity**: Check backup file integrity
3. **Restore Process**: Follow backup restoration procedure
4. **Data Validation**: Verify restored data completeness

#### Soft Delete Recovery
1. **Recently Deleted**: Check "Recently Deleted" section
2. **Archive Search**: Search archives for missing items
3. **Database Query**: Query database for soft-deleted items
4. **Restore Items**: Restore items from soft-delete state

### Application Reset

#### Partial Reset
1. **Clear Cache**: Clear application cache only
2. **Reset Preferences**: Reset user preferences to defaults
3. **Reconnect Services**: Reconnect to external services
4. **Refresh Data**: Force refresh all data from server

#### Complete Reset
1. **Backup Data**: Create backup before reset
2. **Clear All Data**: Remove all local application data
3. **Reinstall**: Reinstall application if necessary
4. **Restore Backup**: Restore data from backup

## Getting Additional Help

### Support Resources
- **Documentation**: Check feature-specific documentation
- **GitHub Issues**: Report bugs on GitHub repository
- **Community Forum**: Join community discussions
- **Direct Support**: Contact development team

### Reporting Issues
When reporting issues, include:
1. **System Information**: macOS version, app version
2. **Steps to Reproduce**: Detailed reproduction steps
3. **Expected Behavior**: What should happen
4. **Actual Behavior**: What actually happens
5. **Error Messages**: Any error messages or logs
6. **Screenshots**: Visual evidence of the issue

### Emergency Contacts
- **Critical Issues**: Use GitHub issues with "critical" label
- **Data Loss**: Contact support immediately
- **Security Issues**: Report security issues privately
- **Service Outages**: Check status page first, then report

This troubleshooting guide covers the most common issues encountered with LifeManager. For issues not covered here, please refer to the specific feature documentation or contact support. 