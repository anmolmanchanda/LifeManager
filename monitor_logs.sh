#!/bin/bash

echo "🔍 Monitoring LifeManager logs..."
echo "Press Ctrl+C to stop"
echo ""
 
# Stream logs and filter for our debug messages
log stream --predicate 'process == "LifeManager"' | grep --line-buffered "🔧" 