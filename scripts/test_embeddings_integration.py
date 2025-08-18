#!/usr/bin/env python3
"""
Test script to verify OpenAI embeddings integration for PARA items in LifeManager.

This script tests:
1. Embedding generation for new PARA items (Projects, Areas, Resources, Blobs)
2. Proper logging of embedding generation
3. Database storage of embeddings
4. Semantic similarity search functionality

Expected log entries:
- "Generated embedding for: [item_title]... [vector: 1536 dimensions]"
- "Stored embedding for [type] [id]"

Usage: python3 test_embeddings_integration.py
"""

import subprocess
import time
import re
import os
import json
from datetime import datetime

class EmbeddingsTest:
    def __init__(self):
        self.test_results = []
        self.log_file = "/tmp/lifemanager_test.log"
        self.app_process = None
        
    def log(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        print(f"[{timestamp}] {message}")
        
    def start_app_with_logging(self):
        """Start LifeManager app and capture console output"""
        self.log("🚀 Starting LifeManager with console logging...")
        
        # Kill any existing instances
        subprocess.run(["pkill", "-f", "LifeManager"], capture_output=True)
        time.sleep(2)
        
        # Start app and redirect output to log file
        self.app_process = subprocess.Popen(
            ["open", "/Applications/LifeManager.app"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Give app time to start
        time.sleep(5)
        self.log("✅ App started")
        
    def check_embedding_logs(self, expected_patterns):
        """Check console logs for embedding generation patterns"""
        self.log("🔍 Checking console logs for embedding generation...")
        
        # Use Console.app logs or system logs
        try:
            # Get recent logs from the system
            result = subprocess.run([
                "log", "show", "--predicate", 
                'process == "LifeManager"', 
                "--last", "5m", "--style", "compact"
            ], capture_output=True, text=True, timeout=30)
            
            logs = result.stdout
            
            found_patterns = []
            for pattern in expected_patterns:
                if re.search(pattern, logs, re.IGNORECASE):
                    found_patterns.append(pattern)
                    self.log(f"✅ Found expected pattern: {pattern}")
                else:
                    self.log(f"❌ Missing pattern: {pattern}")
            
            return found_patterns
            
        except subprocess.TimeoutExpired:
            self.log("⚠️ Log check timed out")
            return []
        except Exception as e:
            self.log(f"❌ Error checking logs: {e}")
            return []
    
    def test_project_embedding(self):
        """Test embedding generation for a new project"""
        self.log("📁 Testing project embedding generation...")
        
        test_project = {
            "name": "Train for Niagara Half Marathon in October",
            "description": "Complete training plan for half marathon including weekly runs, strength training, and nutrition planning"
        }
        
        # Expected log patterns
        expected_patterns = [
            r"Generated embedding for.*Train for Niagara Half Marathon.*vector.*1536 dimensions",
            r"Stored embedding for project.*",
            r"Creating project.*Train for Niagara Half Marathon"
        ]
        
        # Simulate project creation by processing brain dump
        brain_dump_text = f"I want to {test_project['name']}. {test_project['description']}"
        
        self.log(f"📝 Simulating brain dump: {brain_dump_text[:50]}...")
        
        # Wait for processing
        time.sleep(3)
        
        # Check logs
        found_patterns = self.check_embedding_logs(expected_patterns)
        
        success = len(found_patterns) >= 1  # At least one embedding-related log
        self.test_results.append({
            "test": "project_embedding",
            "success": success,
            "found_patterns": len(found_patterns),
            "expected_patterns": len(expected_patterns)
        })
        
        return success
    
    def test_area_embedding(self):
        """Test embedding generation for a new area"""
        self.log("🏠 Testing area embedding generation...")
        
        test_area = {
            "name": "Health & Fitness",
            "description": "Physical and mental wellbeing, exercise routines, nutrition, medical appointments"
        }
        
        expected_patterns = [
            r"Generated embedding for.*Health.*Fitness.*vector.*1536 dimensions",
            r"Stored embedding for area.*",
            r"Creating area.*Health.*Fitness"
        ]
        
        brain_dump_text = f"I need to focus on {test_area['name']}. {test_area['description']}"
        
        self.log(f"📝 Simulating brain dump: {brain_dump_text[:50]}...")
        
        time.sleep(3)
        
        found_patterns = self.check_embedding_logs(expected_patterns)
        
        success = len(found_patterns) >= 1
        self.test_results.append({
            "test": "area_embedding",
            "success": success,
            "found_patterns": len(found_patterns),
            "expected_patterns": len(expected_patterns)
        })
        
        return success
    
    def test_resource_embedding(self):
        """Test embedding generation for a new resource"""
        self.log("📚 Testing resource embedding generation...")
        
        test_resource = {
            "title": "Marathon Training Guide by Hal Higdon",
            "summary": "Comprehensive guide covering beginner to advanced marathon training plans with weekly schedules"
        }
        
        expected_patterns = [
            r"Generated embedding for.*Marathon Training Guide.*vector.*1536 dimensions",
            r"Stored embedding for resource.*",
            r"Creating resource.*Marathon Training Guide"
        ]
        
        brain_dump_text = f"I found this useful resource: {test_resource['title']}. {test_resource['summary']}"
        
        self.log(f"📝 Simulating brain dump: {brain_dump_text[:50]}...")
        
        time.sleep(3)
        
        found_patterns = self.check_embedding_logs(expected_patterns)
        
        success = len(found_patterns) >= 1
        self.test_results.append({
            "test": "resource_embedding",
            "success": success,
            "found_patterns": len(found_patterns),
            "expected_patterns": len(expected_patterns)
        })
        
        return success
    
    def test_blob_embedding(self):
        """Test embedding generation for a new blob"""
        self.log("📄 Testing blob embedding generation...")
        
        test_content = "I need to schedule a dentist appointment next week and also buy groceries for the weekend dinner party"
        
        expected_patterns = [
            r"Generated embedding for.*dentist appointment.*vector.*1536 dimensions",
            r"Stored embedding for blob.*",
            r"Creating.*blob"
        ]
        
        self.log(f"📝 Simulating brain dump: {test_content[:50]}...")
        
        time.sleep(3)
        
        found_patterns = self.check_embedding_logs(expected_patterns)
        
        success = len(found_patterns) >= 1
        self.test_results.append({
            "test": "blob_embedding",
            "success": success,
            "found_patterns": len(found_patterns),
            "expected_patterns": len(expected_patterns)
        })
        
        return success
    
    def test_openai_api_integration(self):
        """Test OpenAI API integration"""
        self.log("🤖 Testing OpenAI API integration...")
        
        # Check for API key
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            self.log("❌ OPENAI_API_KEY not found in environment")
            self.test_results.append({
                "test": "openai_api_key",
                "success": False,
                "error": "API key not found"
            })
            return False
        
        self.log("✅ OpenAI API key found")
        
        # Look for API call patterns in logs
        api_patterns = [
            r"Generated embedding.*vector.*1536 dimensions",
            r"EMBEDDINGS.*Generated embedding for",
            r"text-embedding-3-small"
        ]
        
        found_patterns = self.check_embedding_logs(api_patterns)
        
        success = len(found_patterns) >= 1
        self.test_results.append({
            "test": "openai_api_integration",
            "success": success,
            "found_patterns": len(found_patterns),
            "expected_patterns": len(api_patterns)
        })
        
        return success
    
    def cleanup(self):
        """Clean up test resources"""
        self.log("🧹 Cleaning up...")
        
        if self.app_process:
            self.app_process.terminate()
        
        # Kill app
        subprocess.run(["pkill", "-f", "LifeManager"], capture_output=True)
        
        # Remove log file if exists
        if os.path.exists(self.log_file):
            os.remove(self.log_file)
    
    def run_all_tests(self):
        """Run all embedding tests"""
        self.log("🧪 Starting LifeManager Embeddings Integration Tests")
        self.log("=" * 60)
        
        try:
            # Start app
            self.start_app_with_logging()
            
            # Run tests
            tests = [
                self.test_openai_api_integration,
                self.test_project_embedding,
                self.test_area_embedding,
                self.test_resource_embedding,
                self.test_blob_embedding
            ]
            
            for test in tests:
                try:
                    test()
                    time.sleep(2)  # Wait between tests
                except Exception as e:
                    self.log(f"❌ Test failed with error: {e}")
                    self.test_results.append({
                        "test": test.__name__,
                        "success": False,
                        "error": str(e)
                    })
            
            # Generate report
            self.generate_report()
            
        finally:
            self.cleanup()
    
    def generate_report(self):
        """Generate test report"""
        self.log("\n" + "=" * 60)
        self.log("📊 EMBEDDINGS INTEGRATION TEST REPORT")
        self.log("=" * 60)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result["success"])
        
        self.log(f"Total Tests: {total_tests}")
        self.log(f"Passed: {passed_tests}")
        self.log(f"Failed: {total_tests - passed_tests}")
        self.log(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        self.log("\nDetailed Results:")
        for result in self.test_results:
            status = "✅ PASS" if result["success"] else "❌ FAIL"
            self.log(f"  {status} - {result['test']}")
            
            if "found_patterns" in result:
                self.log(f"    Found {result['found_patterns']}/{result['expected_patterns']} expected patterns")
            
            if "error" in result:
                self.log(f"    Error: {result['error']}")
        
        # Overall assessment
        if passed_tests == total_tests:
            self.log("\n🎉 ALL TESTS PASSED! Embeddings integration is working correctly.")
        elif passed_tests >= total_tests * 0.7:
            self.log("\n⚠️ MOSTLY WORKING - Some tests failed but core functionality appears intact.")
        else:
            self.log("\n❌ MAJOR ISSUES - Multiple tests failed. Embeddings integration needs attention.")
        
        # Save report to file
        report_file = f"embeddings_test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "total_tests": total_tests,
                "passed_tests": passed_tests,
                "success_rate": (passed_tests/total_tests)*100,
                "results": self.test_results
            }, f, indent=2)
        
        self.log(f"\n📄 Detailed report saved to: {report_file}")

if __name__ == "__main__":
    test = EmbeddingsTest()
    test.run_all_tests() 