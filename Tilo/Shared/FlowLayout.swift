import SwiftUI

// Ensure project targets iOS 16+ for Layout protocol
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    // Calculates the combined size of the layout
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) -> CGSize {
        guard let proposedWidth = proposal.width else { return .zero }

        // Calculate heights and arrange subviews mentally
        let dimensions = calculateSubviewDimensions(subviews: subviews, proposedWidth: proposedWidth)
        cache.maxHeightPerRow = dimensions.maxHeightPerRow // Store max heights for placement

        // Total height is sum of row heights + spacing between rows
        let totalHeight = dimensions.maxHeightPerRow.reduce(0, +) + CGFloat(max(0, dimensions.maxHeightPerRow.count - 1)) * verticalSpacing
        
        // Width is constrained by the proposal
        return CGSize(width: proposedWidth, height: totalHeight)
    }

    // Places the subviews within the given bounds
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout CacheData
    ) {
        guard !subviews.isEmpty else { return }
        guard let proposedWidth = proposal.width else { return } // Should have width from sizeThatFits

        let dimensions = calculateSubviewDimensions(subviews: subviews, proposedWidth: proposedWidth)
        
        // Use cached max heights if available, otherwise recalculate (should be cached)
        let maxHeightPerRow = cache.maxHeightPerRow ?? dimensions.maxHeightPerRow

        var currentX = bounds.minX
        var currentY = bounds.minY
        var currentRowIndex = 0

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified) // Get ideal size

            // Check if subview fits in the current row
            if currentX + subviewSize.width > bounds.minX + proposedWidth {
                // Move to the next row
                currentX = bounds.minX
                currentY += maxHeightPerRow[currentRowIndex] + verticalSpacing
                currentRowIndex += 1
                
                // Handle edge case where a single item is wider than the proposed width
                if currentRowIndex >= maxHeightPerRow.count {
                    currentRowIndex = maxHeightPerRow.count - 1 
                    if currentRowIndex < 0 { currentRowIndex = 0 }
                 }
            }
            
            // Ensure we don't exceed bounds, especially vertically
             guard currentRowIndex < maxHeightPerRow.count else {
                 continue
             }


            // Center subview vertically within its row using the max height for that row
            let rowMaxHeight = maxHeightPerRow[currentRowIndex]
            let verticalOffset = (rowMaxHeight - subviewSize.height) / 2.0
            
            let placementProposal = ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
            
            subview.place(
                at: CGPoint(x: currentX, y: currentY + verticalOffset),
                anchor: .topLeading,
                proposal: placementProposal
            )

            // Move X for the next subview
            currentX += subviewSize.width + horizontalSpacing
        }
    }
    
    // Helper function to calculate row heights and arrangement
    // This logic is used by both sizeThatFits and placeSubviews
    private func calculateSubviewDimensions(subviews: Subviews, proposedWidth: CGFloat) -> (totalHeight: CGFloat, maxHeightPerRow: [CGFloat]) {
        var currentRowWidth: CGFloat = 0
        var currentRowMaxHeight: CGFloat = 0
        var maxHeightPerRow: [CGFloat] = []

        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)

            // Check if subview fits in the current row
            if currentRowWidth == 0 || currentRowWidth + horizontalSpacing + subviewSize.width <= proposedWidth {
                // Add to current row
                currentRowWidth += (currentRowWidth == 0 ? 0 : horizontalSpacing) + subviewSize.width
                currentRowMaxHeight = max(currentRowMaxHeight, subviewSize.height)
            } else {
                // Move to the next row
                maxHeightPerRow.append(currentRowMaxHeight) // Store max height of completed row
                currentRowWidth = subviewSize.width
                currentRowMaxHeight = subviewSize.height
            }
        }
        
        // Add the last row's max height
        if currentRowMaxHeight > 0 {
             maxHeightPerRow.append(currentRowMaxHeight)
        }

        let totalHeight = maxHeightPerRow.reduce(0, +) + CGFloat(max(0, maxHeightPerRow.count - 1)) * verticalSpacing
        
        return (totalHeight, maxHeightPerRow)
    }

    // Cache to store calculated row heights between sizeThatFits and placeSubviews
    struct CacheData {
        var maxHeightPerRow: [CGFloat]?
    }

    // Creates an empty cache instance
    func makeCache(subviews: Subviews) -> CacheData {
        return CacheData()
    }
} 