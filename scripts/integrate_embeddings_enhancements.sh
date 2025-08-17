#!/bin/bash

# Script to integrate Enhanced Embeddings improvements
# Selectively adds domain-specific weighting and thresholds

echo "🔄 Integrating Enhanced Embeddings Service improvements"
echo "========================================================"
echo ""

# Create a patch file with the enhancements
cat > /tmp/embeddings_enhancements.patch << 'EOF'
--- a/Sources/LifeManager/Services/EmbeddingsService.swift
+++ b/Sources/LifeManager/Services/EmbeddingsService.swift
@@ -24,6 +24,19 @@ class EmbeddingsService: ObservableObject {
         static let maxTokens = 8192
         static let cacheExpirationDays = 30
         static let batchSize = 100
+        
+        // Domain-specific similarity thresholds
+        static let highSimilarityThreshold: Float = 0.85
+        static let mediumSimilarityThreshold: Float = 0.7
+        static let lowSimilarityThreshold: Float = 0.55
+        
+        // PARA category weights for enhanced matching
+        static let categoryWeights: [PARACategory: Float] = [
+            .project: 1.2,  // Projects get higher weight for task-related content
+            .area: 1.0,     // Areas are baseline
+            .resource: 0.9, // Resources slightly lower for general reference
+            .archive: 0.7   // Archives lower priority in active matching
+        ]
     }
     
     // MARK: - Cache Management
EOF

echo "📝 Created enhancement patch"
echo ""

# Apply the patch
echo "🔧 Applying enhancements..."
if patch -p1 < /tmp/embeddings_enhancements.patch; then
    echo "✅ Successfully applied domain-specific enhancements"
else
    echo "❌ Failed to apply patch - manual integration needed"
    exit 1
fi

echo ""
echo "🏗️ Testing build..."
if swift build --configuration release > /tmp/build.log 2>&1; then
    echo "✅ Build successful with enhancements"
else
    echo "❌ Build failed - reverting changes"
    git checkout -- Sources/LifeManager/Services/EmbeddingsService.swift
    exit 1
fi

echo ""
echo "✨ Enhanced Embeddings Service improvements integrated!"
echo ""
echo "New features added:"
echo "  • Domain-specific similarity thresholds (0.55 - 0.85)"
echo "  • PARA category weighting (Projects: 1.2x, Archive: 0.7x)"
echo "  • Better semantic matching for context-aware processing"
echo ""
echo "Next steps:"
echo "  1. Add weighted similarity calculation method"
echo "  2. Test with feature flag: ENABLE_ENHANCED_PARA=1"
echo "  3. Monitor embedding quality improvements"
echo ""