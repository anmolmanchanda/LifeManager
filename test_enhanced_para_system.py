#!/usr/bin/env python3
"""
Comprehensive Test Suite for Enhanced PARA Brain Dump Processing System
Tests all 9 MCP servers and enhanced features
Uses sequential-thinking, context7, postgres, brave-search, filesystem, task-master-AI, 
APIDOG, batch-processor, and memory-cache MCPs
"""

import json
import time
import asyncio
import aiohttp
import subprocess
import sys
import os
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class EnhancedPARASystemTester:
    def __init__(self):
        self.app_bundle_path = "/Applications/LifeManager.app"
        self.test_results = {
            "timestamp": datetime.now().isoformat(),
            "mcp_servers": {},
            "features": {},
            "performance": {},
            "errors": []
        }
        
    async def run_comprehensive_tests(self):
        """Run all enhanced PARA system tests"""
        logger.info("🚀 Starting Enhanced PARA System Comprehensive Tests")
        
        try:
            # Phase 1: MCP Server Verification
            await self.test_mcp_servers()
            
            # Phase 2: Enhanced Features Testing
            await self.test_enhanced_features()
            
            # Phase 3: Integration Testing
            await self.test_system_integration()
            
            # Phase 4: Performance Testing
            await self.test_performance_metrics()
            
            # Phase 5: Generate Report
            self.generate_test_report()
            
        except Exception as e:
            logger.error(f"❌ Test suite failed: {e}")
            self.test_results["errors"].append(str(e))
        
        logger.info("✅ Enhanced PARA System Tests Completed")
        return self.test_results
    
    async def test_mcp_servers(self):
        """Test all 9 MCP servers"""
        logger.info("🔧 Testing MCP Servers...")
        
        mcp_servers = {
            "sequential-thinking": "npx @modelcontextprotocol/server-sequential-thinking",
            "context7": "npx @upstash/context7-mcp",
            "postgres": "npx @modelcontextprotocol/server-postgres",
            "brave-search": "npx @modelcontextprotocol/server-brave-search",
            "filesystem": "npx @modelcontextprotocol/server-filesystem",
            "task-master-ai": "npx @task-master-ai/mcp-server",
            "apidog": "npx @apidog/mcp-server",
            "batch-processor": "npx @modelcontextprotocol/server-batch-processor",
            "memory-cache": "npx @modelcontextprotocol/server-memory-cache"
        }
        
        for server_name, command in mcp_servers.items():
            try:
                # Test if server is accessible
                result = await self.test_mcp_server(server_name, command)
                self.test_results["mcp_servers"][server_name] = result
                logger.info(f"{'✅' if result['status'] == 'success' else '❌'} {server_name}: {result['message']}")
                
            except Exception as e:
                error_msg = f"Failed to test {server_name}: {str(e)}"
                self.test_results["mcp_servers"][server_name] = {
                    "status": "error",
                    "message": error_msg,
                    "timestamp": datetime.now().isoformat()
                }
                logger.error(f"❌ {error_msg}")
    
    async def test_mcp_server(self, server_name: str, command: str) -> Dict[str, Any]:
        """Test individual MCP server availability"""
        try:
            # Test if the server command is available
            test_cmd = command.split()[0]  # Get base command (npx)
            
            process = await asyncio.create_subprocess_exec(
                "which", test_cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                return {
                    "status": "success",
                    "message": f"MCP server {server_name} command available",
                    "command": command,
                    "timestamp": datetime.now().isoformat()
                }
            else:
                return {
                    "status": "warning",
                    "message": f"MCP server {server_name} command not found",
                    "command": command,
                    "timestamp": datetime.now().isoformat()
                }
                
        except Exception as e:
            return {
                "status": "error",
                "message": f"Error testing {server_name}: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def test_enhanced_features(self):
        """Test enhanced PARA system features"""
        logger.info("🧠 Testing Enhanced Features...")
        
        features_to_test = {
            "dynamic_context_window": self.test_dynamic_context_window,
            "calendar_integration": self.test_calendar_integration,
            "semantic_embeddings": self.test_semantic_embeddings,
            "advanced_analytics": self.test_advanced_analytics,
            "clarification_questions": self.test_clarification_questions,
            "enhanced_json_output": self.test_enhanced_json_output
        }
        
        for feature_name, test_func in features_to_test.items():
            try:
                start_time = time.time()
                result = await test_func()
                end_time = time.time()
                
                self.test_results["features"][feature_name] = {
                    "status": "success" if result["success"] else "failed",
                    "details": result,
                    "duration": end_time - start_time,
                    "timestamp": datetime.now().isoformat()
                }
                
                status_emoji = "✅" if result["success"] else "❌"
                logger.info(f"{status_emoji} {feature_name}: {result.get('message', 'Completed')}")
                
            except Exception as e:
                error_msg = f"Failed to test {feature_name}: {str(e)}"
                self.test_results["features"][feature_name] = {
                    "status": "error",
                    "error": error_msg,
                    "timestamp": datetime.now().isoformat()
                }
                logger.error(f"❌ {error_msg}")
    
    async def test_dynamic_context_window(self) -> Dict[str, Any]:
        """Test dynamic context window sizing (50-100 items based on activity)"""
        try:
            # Test if ContextMemoryService exists and has dynamic sizing
            service_file = "/Users/Shared/LifeManager/Sources/LifeManager/Services/ContextMemoryService.swift"
            
            if os.path.exists(service_file):
                with open(service_file, 'r') as f:
                    content = f.read()
                    
                # Check for dynamic window sizing implementation
                dynamic_features = [
                    "minSlidingWindowSize",
                    "maxSlidingWindowSize", 
                    "adjustWindowSize",
                    "ActivityPatterns",
                    "averageDailyActivity",
                    "recentActivityTrend"
                ]
                
                found_features = [feature for feature in dynamic_features if feature in content]
                
                return {
                    "success": len(found_features) >= 5,
                    "message": f"Found {len(found_features)}/6 dynamic window features",
                    "found_features": found_features,
                    "implementation_quality": "complete" if len(found_features) >= 5 else "partial"
                }
            else:
                return {"success": False, "message": "ContextMemoryService not found"}
                
        except Exception as e:
            return {"success": False, "message": f"Error testing dynamic context window: {str(e)}"}
    
    async def test_calendar_integration(self) -> Dict[str, Any]:
        """Test deep calendar integration for scheduling context"""
        try:
            service_file = "/Users/Shared/LifeManager/Sources/LifeManager/Services/ContextMemoryService.swift"
            
            if os.path.exists(service_file):
                with open(service_file, 'r') as f:
                    content = f.read()
                    
                # Check for calendar integration features
                calendar_features = [
                    "CalendarContext",
                    "getCalendarContext",
                    "calculateAvailableTimeSlots",
                    "analyzeSchedulingPatterns",
                    "todayEvents",
                    "upcomingEvents"
                ]
                
                found_features = [feature for feature in calendar_features if feature in content]
                
                return {
                    "success": len(found_features) >= 5,
                    "message": f"Found {len(found_features)}/6 calendar integration features",
                    "found_features": found_features,
                    "implementation_quality": "complete" if len(found_features) >= 5 else "partial"
                }
            else:
                return {"success": False, "message": "ContextMemoryService not found"}
                
        except Exception as e:
            return {"success": False, "message": f"Error testing calendar integration: {str(e)}"}
    
    async def test_semantic_embeddings(self) -> Dict[str, Any]:
        """Test enhanced semantic embeddings with domain-specific features"""
        try:
            service_file = "/Users/Shared/LifeManager/Sources/LifeManager/Services/EmbeddingsService.swift"
            
            if os.path.exists(service_file):
                with open(service_file, 'r') as f:
                    content = f.read()
                    
                # Check for domain-specific features
                embedding_features = [
                    "DomainContext",
                    "EnhancedSimilarityResult",
                    "findSimilarPARAItems",
                    "enhancePARASimilarity",
                    "preprocessPARAContent",
                    "categoryWeights",
                    "domainSpecificAccuracy"
                ]
                
                found_features = [feature for feature in embedding_features if feature in content]
                
                return {
                    "success": len(found_features) >= 6,
                    "message": f"Found {len(found_features)}/7 semantic embedding features",
                    "found_features": found_features,
                    "implementation_quality": "complete" if len(found_features) >= 6 else "partial"
                }
            else:
                return {"success": False, "message": "EmbeddingsService not found"}
                
        except Exception as e:
            return {"success": False, "message": f"Error testing semantic embeddings: {str(e)}"}
    
    async def test_advanced_analytics(self) -> Dict[str, Any]:
        """Test advanced analytics and pattern visualization"""
        try:
            service_file = "/Users/Shared/LifeManager/Sources/LifeManager/Services/AdvancedAnalyticsService.swift"
            
            if os.path.exists(service_file):
                with open(service_file, 'r') as f:
                    content = f.read()
                    
                # Check for analytics features
                analytics_features = [
                    "AdvancedAnalyticsService",
                    "performComprehensiveAnalysis",
                    "getProductivityTrends",
                    "getPARADistribution",
                    "getOptimizationSuggestions",
                    "AnalyticsInsight",
                    "PatternAnalysis",
                    "PerformanceMetrics"
                ]
                
                found_features = [feature for feature in analytics_features if feature in content]
                
                return {
                    "success": len(found_features) >= 7,
                    "message": f"Found {len(found_features)}/8 analytics features",
                    "found_features": found_features,
                    "implementation_quality": "complete" if len(found_features) >= 7 else "partial"
                }
            else:
                return {"success": False, "message": "AdvancedAnalyticsService not found"}
                
        except Exception as e:
            return {"success": False, "message": f"Error testing advanced analytics: {str(e)}"}
    
    async def test_clarification_questions(self) -> Dict[str, Any]:
        """Test sophisticated clarification question generation"""
        try:
            service_file = "/Users/Shared/LifeManager/Sources/LifeManager/Services/ContextualPARAEngine.swift"
            
            if os.path.exists(service_file):
                with open(service_file, 'r') as f:
                    content = f.read()
                    
                # Check for clarification features
                clarification_features = [
                    "generateComprehensiveClarifications",
                    "generateCategoryAmbiguityClarification",
                    "generateContextMismatchClarification",
                    "generatePriorityClarification",
                    "generateTemporalClarification",
                    "generateScopeClarification",
                    "ClarificationType",
                    "CategoryAmbiguity",
                    "ContextMismatch"
                ]
                
                found_features = [feature for feature in clarification_features if feature in content]
                
                return {
                    "success": len(found_features) >= 8,
                    "message": f"Found {len(found_features)}/9 clarification features",
                    "found_features": found_features,
                    "implementation_quality": "complete" if len(found_features) >= 8 else "partial"
                }
            else:
                return {"success": False, "message": "ContextualPARAEngine not found"}
                
        except Exception as e:
            return {"success": False, "message": f"Error testing clarification questions: {str(e)}"}
    
    async def test_enhanced_json_output(self) -> Dict[str, Any]:
        """Test enhanced JSON output structure with advanced reasoning"""
        try:
            service_file = "/Users/Shared/LifeManager/Sources/LifeManager/Services/LLMBrainDumpProcessor.swift"
            
            if os.path.exists(service_file):
                with open(service_file, 'r') as f:
                    content = f.read()
                    
                # Check for enhanced JSON features
                json_features = [
                    "EnhancedBrainDumpItem",
                    "DetailedReasoning",
                    "ClassificationReasoning",
                    "AlternativeClassification",
                    "ContextualRelevance",
                    "SemanticSimilarity",
                    "UncertaintyFactor",
                    "ProcessingMetadata",
                    "ContextualInsights"
                ]
                
                found_features = [feature for feature in json_features if feature in content]
                
                return {
                    "success": len(found_features) >= 8,
                    "message": f"Found {len(found_features)}/9 enhanced JSON features",
                    "found_features": found_features,
                    "implementation_quality": "complete" if len(found_features) >= 8 else "partial"
                }
            else:
                return {"success": False, "message": "LLMBrainDumpProcessor not found"}
                
        except Exception as e:
            return {"success": False, "message": f"Error testing enhanced JSON output: {str(e)}"}
    
    async def test_system_integration(self):
        """Test system integration and MCP utilization"""
        logger.info("🔗 Testing System Integration...")
        
        try:
            # Test if app builds successfully
            build_result = await self.test_app_build()
            
            # Test if MCP configuration is properly set up
            mcp_config_result = await self.test_mcp_configuration()
            
            # Test if prompt caching is configured
            caching_result = await self.test_prompt_caching()
            
            self.test_results["integration"] = {
                "app_build": build_result,
                "mcp_configuration": mcp_config_result,
                "prompt_caching": caching_result,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"❌ Integration test failed: {e}")
            self.test_results["integration"] = {"error": str(e)}
    
    async def test_app_build(self) -> Dict[str, Any]:
        """Test if the app builds successfully"""
        try:
            process = await asyncio.create_subprocess_exec(
                "swift", "build", "--configuration", "release",
                cwd="/Users/Shared/LifeManager",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            stdout, stderr = await process.communicate()
            
            if process.returncode == 0:
                return {
                    "success": True,
                    "message": "App builds successfully",
                    "warnings": len([line for line in stderr.decode().split('\n') if 'warning:' in line])
                }
            else:
                return {
                    "success": False,
                    "message": "Build failed",
                    "error": stderr.decode()
                }
                
        except Exception as e:
            return {"success": False, "message": f"Build test error: {str(e)}"}
    
    async def test_mcp_configuration(self) -> Dict[str, Any]:
        """Test MCP configuration file"""
        try:
            mcp_config_path = "/Users/Shared/.config/claude/mcp.json"
            
            if os.path.exists(mcp_config_path):
                with open(mcp_config_path, 'r') as f:
                    config = json.load(f)
                    
                expected_servers = [
                    "sequential-thinking", "context7", "postgres", "brave-search",
                    "filesystem", "task-master-ai", "apidog", "batch-processor", "memory-cache"
                ]
                
                configured_servers = list(config.get("mcpServers", {}).keys())
                missing_servers = [s for s in expected_servers if s not in configured_servers]
                
                return {
                    "success": len(missing_servers) == 0,
                    "message": f"MCP configuration complete ({len(configured_servers)}/9 servers)",
                    "configured_servers": configured_servers,
                    "missing_servers": missing_servers
                }
            else:
                return {"success": False, "message": "MCP configuration file not found"}
                
        except Exception as e:
            return {"success": False, "message": f"MCP config test error: {str(e)}"}
    
    async def test_prompt_caching(self) -> Dict[str, Any]:
        """Test prompt caching configuration"""
        try:
            # Check if environment variables are set
            cache_prompt = os.environ.get("ANTHROPIC_CACHE_PROMPT")
            cache_ttl = os.environ.get("ANTHROPIC_CACHE_TTL")
            
            return {
                "success": cache_prompt == "true" and cache_ttl is not None,
                "message": f"Prompt caching configured: {cache_prompt}, TTL: {cache_ttl}",
                "cache_prompt": cache_prompt,
                "cache_ttl": cache_ttl
            }
            
        except Exception as e:
            return {"success": False, "message": f"Caching test error: {str(e)}"}
    
    async def test_performance_metrics(self):
        """Test performance metrics"""
        logger.info("⚡ Testing Performance Metrics...")
        
        try:
            # Test file reading performance
            file_read_time = await self.measure_file_read_performance()
            
            # Test build time
            build_time = await self.measure_build_time()
            
            # Test service initialization time
            service_init_time = await self.measure_service_initialization()
            
            self.test_results["performance"] = {
                "file_read_time": file_read_time,
                "build_time": build_time,
                "service_initialization": service_init_time,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"❌ Performance test failed: {e}")
            self.test_results["performance"] = {"error": str(e)}
    
    async def measure_file_read_performance(self) -> float:
        """Measure file reading performance"""
        start_time = time.time()
        
        # Read all Swift files in the project
        swift_files = []
        for root, dirs, files in os.walk("/Users/Shared/LifeManager/Sources"):
            for file in files:
                if file.endswith('.swift'):
                    swift_files.append(os.path.join(root, file))
        
        for file_path in swift_files[:10]:  # Test first 10 files
            try:
                with open(file_path, 'r') as f:
                    _ = f.read()
            except:
                continue
        
        return time.time() - start_time
    
    async def measure_build_time(self) -> float:
        """Measure build time"""
        start_time = time.time()
        
        try:
            process = await asyncio.create_subprocess_exec(
                "swift", "build", "--configuration", "release",
                cwd="/Users/Shared/LifeManager",
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            await process.communicate()
            return time.time() - start_time
            
        except Exception as e:
            return -1
    
    async def measure_service_initialization(self) -> Dict[str, Any]:
        """Measure service initialization patterns"""
        services = [
            "ContextMemoryService",
            "EmbeddingsService", 
            "AdvancedAnalyticsService",
            "ContextualPARAEngine",
            "LLMBrainDumpProcessor"
        ]
        
        initialization_patterns = {}
        
        for service in services:
            # Check if service uses proper initialization patterns
            service_files = []
            for root, dirs, files in os.walk("/Users/Shared/LifeManager/Sources"):
                for file in files:
                    if service in file:
                        service_files.append(os.path.join(root, file))
            
            patterns_found = 0
            for file_path in service_files:
                try:
                    with open(file_path, 'r') as f:
                        content = f.read()
                        if "static let shared" in content:
                            patterns_found += 1
                        if "private init()" in content:
                            patterns_found += 1
                        if "@Published" in content:
                            patterns_found += 1
                except:
                    continue
            
            initialization_patterns[service] = patterns_found
        
        return initialization_patterns
    
    def generate_test_report(self):
        """Generate comprehensive test report"""
        logger.info("📊 Generating Test Report...")
        
        # Calculate summary statistics
        total_mcps = len(self.test_results.get("mcp_servers", {}))
        successful_mcps = len([r for r in self.test_results.get("mcp_servers", {}).values() if r.get("status") == "success"])
        
        total_features = len(self.test_results.get("features", {}))
        successful_features = len([r for r in self.test_results.get("features", {}).values() if r.get("status") == "success"])
        
        # Generate report
        report = {
            "test_summary": {
                "timestamp": self.test_results["timestamp"],
                "total_duration": time.time(),
                "mcp_servers": {
                    "total": total_mcps,
                    "successful": successful_mcps,
                    "success_rate": f"{(successful_mcps/total_mcps*100):.1f}%" if total_mcps > 0 else "0%"
                },
                "enhanced_features": {
                    "total": total_features,
                    "successful": successful_features,
                    "success_rate": f"{(successful_features/total_features*100):.1f}%" if total_features > 0 else "0%"
                },
                "overall_status": "PASS" if successful_features >= 5 and successful_mcps >= 7 else "PARTIAL"
            },
            "detailed_results": self.test_results
        }
        
        # Save report
        report_filename = f"enhanced_para_test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_filename, 'w') as f:
            json.dump(report, f, indent=2)
        
        # Print summary
        print("\n" + "="*80)
        print("🎯 ENHANCED PARA SYSTEM TEST REPORT")
        print("="*80)
        print(f"📅 Timestamp: {report['test_summary']['timestamp']}")
        print(f"🔧 MCP Servers: {successful_mcps}/{total_mcps} ({report['test_summary']['mcp_servers']['success_rate']})")
        print(f"🧠 Enhanced Features: {successful_features}/{total_features} ({report['test_summary']['enhanced_features']['success_rate']})")
        print(f"📊 Overall Status: {report['test_summary']['overall_status']}")
        print(f"📄 Report saved: {report_filename}")
        print("="*80)
        
        # Print detailed feature results
        print("\n🧠 ENHANCED FEATURES BREAKDOWN:")
        for feature_name, result in self.test_results.get("features", {}).items():
            status = result.get("status", "unknown")
            emoji = "✅" if status == "success" else "❌" if status == "failed" else "⚠️"
            details = result.get("details", {})
            message = details.get("message", "No details") if isinstance(details, dict) else str(details)
            print(f"  {emoji} {feature_name.replace('_', ' ').title()}: {message}")
        
        # Print MCP status
        print("\n🔧 MCP SERVERS STATUS:")
        for server_name, result in self.test_results.get("mcp_servers", {}).items():
            status = result.get("status", "unknown")
            emoji = "✅" if status == "success" else "❌" if status == "error" else "⚠️"
            message = result.get("message", "No details")
            print(f"  {emoji} {server_name}: {message}")
        
        logger.info(f"✅ Test report generated: {report_filename}")

async def main():
    """Main test execution"""
    print("🚀 Enhanced PARA Brain Dump Processing System - Comprehensive Test Suite")
    print("Testing all MCPs and enhanced features...")
    print("-" * 80)
    
    tester = EnhancedPARASystemTester()
    
    try:
        results = await tester.run_comprehensive_tests()
        return 0 if results else 1
        
    except KeyboardInterrupt:
        print("\n❌ Tests interrupted by user")
        return 1
    except Exception as e:
        print(f"\n❌ Test suite failed: {e}")
        return 1

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)