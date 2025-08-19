#!/usr/bin/env python3
"""
Comprehensive Feature Testing Script for LifeManager
Tests all the new features and improvements made to the brain dump system
"""

import time
import subprocess
import sys

def print_header(title):
    print(f"\n{'='*60}")
    print(f"🧪 {title}")
    print(f"{'='*60}")

def print_test(test_name):
    print(f"\n🔍 Testing: {test_name}")

def print_success(message):
    print(f"✅ {message}")

def print_warning(message):
    print(f"⚠️  {message}")

def print_error(message):
    print(f"❌ {message}")

def wait_for_user_input(prompt):
    return input(f"\n👤 {prompt}: ")

def main():
    print_header("LIFEMANAGER COMPREHENSIVE FEATURE TESTING")
    
    print("""
This script will guide you through testing all the new features:

1. 🧠 Brain Dump Processing with OpenAI API
2. 📅 Calendar Event Editing & Lock System  
3. 🎨 UI Improvements (Sidebar, Areas, History)
4. 🔧 PARA Categorization Accuracy
5. 💾 Database Persistence Verification

Make sure LifeManager is running before proceeding.
    """)
    
    if wait_for_user_input("Ready to start testing? (y/n)").lower() != 'y':
        print("Testing cancelled.")
        return
    
    # Test 1: Brain Dump Processing
    print_header("TEST 1: BRAIN DUMP PROCESSING")
    
    test_input = """Buy oat milk and groceries this weekend. Update my resume with new UN project. Schedule annual physical checkup and dentist appointment. Read "Deep Work" by Cal Newport, jot down best ideas. Follow up with Sarah about Toronto trip dates. Organize apartment rental documents, check lease end date. Make a list of books to read for 2025. Pay credit card bill before 20th. Research best productivity podcasts. Join local running club for marathon training. Draft outline for LifeManager v2.0 roadmap. Add notes from last therapy session to journal. Try that new vegan curry recipe from NYT Cooking. File taxes for 2024. Backup all photos to external drive. Share weekly progress report with the UN team. Move "Completed Tasks" doc to Archives. Store last year's investment statements. Renew Apple Developer account before expiry. Bookmark "SwiftUI advanced animations" tutorial."""
    
    print(f"📝 Test Input:\n{test_input}")
    
    print_test("OpenAI API Integration")
    print("1. Go to Inbox tab in LifeManager")
    print("2. Paste the test input above into the natural language bar")
    print("3. Click 'Process Brain Dump'")
    print("4. Wait for processing (up to 60 seconds)")
    
    api_working = wait_for_user_input("Did the processing use OpenAI API (not fallback)? (y/n)").lower() == 'y'
    
    if api_working:
        print_success("OpenAI API integration working")
    else:
        print_error("OpenAI API not working - check config.txt and API key")
        return
    
    print_test("PARA Categorization Accuracy")
    print("Expected categorization:")
    print("📁 PROJECTS: Update resume, File taxes, Draft LifeManager roadmap, Organize documents")
    print("🏠 AREAS: Pay credit card (Finance), Schedule checkup (Health), Join running club (Health)")
    print("📚 RESOURCES: Read Deep Work, Research podcasts, Try curry recipe, Bookmark tutorial")
    print("📦 ARCHIVES: Move to Archives, Store statements, Backup photos")
    
    categorization_correct = wait_for_user_input("Was the categorization accurate per PARA method? (y/n)").lower() == 'y'
    
    if categorization_correct:
        print_success("PARA categorization working correctly")
    else:
        print_warning("PARA categorization needs adjustment")
    
    print_test("Item Count and Separation")
    item_count = wait_for_user_input("How many separate items were created? (expected: 15-20)")
    
    try:
        count = int(item_count)
        if 15 <= count <= 25:
            print_success(f"Good item separation: {count} items created")
        else:
            print_warning(f"Item separation may need adjustment: {count} items")
    except:
        print_error("Invalid item count entered")
    
    # Test 2: Database Persistence
    print_header("TEST 2: DATABASE PERSISTENCE")
    
    print_test("Data Persistence Verification")
    print("1. Check if items appear in their respective tabs:")
    print("   - Tasks tab should show task items")
    print("   - Resources tab should show learning materials")
    print("   - Areas tab should show ongoing responsibilities")
    print("   - Projects tab should show specific outcomes")
    
    persistence_working = wait_for_user_input("Are items properly saved and visible in tabs? (y/n)").lower() == 'y'
    
    if persistence_working:
        print_success("Database persistence working correctly")
    else:
        print_error("Database persistence issue - items not saving")
    
    # Test 3: Calendar Features
    print_header("TEST 3: CALENDAR EVENT EDITING & LOCK SYSTEM")
    
    print_test("Event Edit UI")
    print("1. Go to Calendar tab")
    print("2. Right-click on any event")
    print("3. Select 'Edit Event'")
    print("4. Verify popup shows with title, start/end time fields")
    
    edit_ui_working = wait_for_user_input("Does the edit popup appear correctly? (y/n)").lower() == 'y'
    
    if edit_ui_working:
        print_success("Event edit UI working")
    else:
        print_error("Event edit UI not working")
    
    print_test("Lock System")
    print("1. Right-click on an unlocked event")
    print("2. Select 'Lock' from context menu")
    print("3. Right-click the same event again")
    print("4. Verify 'Edit', 'Duplicate', 'Delete' are disabled/hidden")
    print("5. Verify 'Unlock' option is available")
    
    lock_system_working = wait_for_user_input("Does the lock system work correctly? (y/n)").lower() == 'y'
    
    if lock_system_working:
        print_success("Lock system working correctly")
    else:
        print_error("Lock system not working")
    
    # Test 4: UI Improvements
    print_header("TEST 4: UI IMPROVEMENTS")
    
    print_test("Sidebar Navigation Order")
    print("Check sidebar shows: Focus, Calendar, Timeline, Mind Map, Tags, Advanced Search")
    
    sidebar_correct = wait_for_user_input("Is sidebar order correct? (y/n)").lower() == 'y'
    
    if sidebar_correct:
        print_success("Sidebar navigation updated correctly")
    else:
        print_warning("Sidebar order needs adjustment")
    
    print_test("Inbox History")
    print("1. Go back to Inbox tab")
    print("2. Check bottom of inbox area")
    print("3. Verify last processed input shows with timestamp and item counts")
    
    history_working = wait_for_user_input("Is inbox history visible? (y/n)").lower() == 'y'
    
    if history_working:
        print_success("Inbox history feature working")
    else:
        print_warning("Inbox history not visible")
    
    print_test("Areas Tab Enhancement")
    print("1. Go to Areas tab")
    print("2. Click on any area card")
    print("3. Verify it expands to show content items")
    print("4. Check for blob count badges")
    
    areas_enhanced = wait_for_user_input("Are Areas tab enhancements working? (y/n)").lower() == 'y'
    
    if areas_enhanced:
        print_success("Areas tab enhancements working")
    else:
        print_warning("Areas tab enhancements not working")
    
    # Test 5: Performance and Reliability
    print_header("TEST 5: PERFORMANCE & RELIABILITY")
    
    print_test("Processing Speed")
    processing_time = wait_for_user_input("How long did brain dump processing take? (seconds)")
    
    try:
        time_seconds = float(processing_time)
        if time_seconds <= 60:
            print_success(f"Processing time acceptable: {time_seconds}s")
        else:
            print_warning(f"Processing time high: {time_seconds}s")
    except:
        print_warning("Invalid processing time entered")
    
    print_test("Error Handling")
    print("1. Try processing empty input")
    print("2. Try processing very long input (1000+ words)")
    print("3. Verify appropriate error messages or handling")
    
    error_handling = wait_for_user_input("Does error handling work properly? (y/n)").lower() == 'y'
    
    if error_handling:
        print_success("Error handling working correctly")
    else:
        print_warning("Error handling needs improvement")
    
    # Final Summary
    print_header("TESTING SUMMARY")
    
    tests = [
        ("OpenAI API Integration", api_working),
        ("PARA Categorization", categorization_correct),
        ("Database Persistence", persistence_working),
        ("Event Edit UI", edit_ui_working),
        ("Lock System", lock_system_working),
        ("Sidebar Navigation", sidebar_correct),
        ("Inbox History", history_working),
        ("Areas Enhancement", areas_enhanced),
        ("Error Handling", error_handling)
    ]
    
    passed = sum(1 for _, result in tests if result)
    total = len(tests)
    
    print(f"\n📊 Test Results: {passed}/{total} tests passed")
    
    for test_name, result in tests:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"   {status} - {test_name}")
    
    if passed == total:
        print_success("🎉 ALL TESTS PASSED! LifeManager is ready for production use.")
    elif passed >= total * 0.8:
        print_warning(f"⚠️  Most tests passed ({passed}/{total}). Minor issues to address.")
    else:
        print_error(f"❌ Multiple issues found ({passed}/{total}). Needs attention.")
    
    print("\n📝 Next Steps:")
    if passed < total:
        print("1. Address failing tests")
        print("2. Re-run testing")
        print("3. Verify fixes work correctly")
    else:
        print("1. App is ready for production use")
        print("2. Monitor performance in real usage")
        print("3. Collect user feedback for improvements")

if __name__ == "__main__":
    main() 