import UIKit

/// Role: Presentation. Hexagonal UICollectionViewLayout. Each brick is a cell, not a row.
final class HexKilnLayout: UICollectionViewLayout {
    var hexHeight: CGFloat = 128
    var gap: CGFloat = 8

    private var attributes: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero

    override var collectionViewContentSize: CGSize { contentSize }

    override func prepare() {
        attributes.removeAll(keepingCapacity: true)
        guard let collectionView else {
            contentSize = .zero
            return
        }
        let count = collectionView.numberOfItems(inSection: 0)
        let width = collectionView.bounds.width
        let frames = Self.frames(count: count, width: width, hexHeight: hexHeight, gap: gap)
        var maxY: CGFloat = 0
        for (index, frame) in frames.enumerated() {
            let item = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: index, section: 0))
            item.frame = frame
            attributes.append(item)
            maxY = max(maxY, frame.maxY)
        }
        contentSize = CGSize(width: width, height: count == 0 ? 0 : maxY + gap)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        attributes.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard attributes.indices.contains(indexPath.item) else { return nil }
        return attributes[indexPath.item]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView?.bounds.size != newBounds.size
    }

    static func measure(count: Int, width: CGFloat, hexHeight: CGFloat = 128, gap: CGFloat = 8) -> CGFloat {
        let frames = frames(count: count, width: width, hexHeight: hexHeight, gap: gap)
        return (frames.map(\.maxY).max() ?? 0) + (count == 0 ? 0 : gap)
    }

    static func frames(
        count: Int,
        width: CGFloat,
        hexHeight: CGFloat,
        gap: CGFloat
    ) -> [CGRect] {
        guard count > 0, width > 1 else { return [] }
        let hexWidth = hexHeight * CGFloat(3).squareRoot() / 2
        let xStride = hexWidth + gap
        let yStride = hexHeight * 0.75 + gap
        let columns = max(1, Int((width + gap) / xStride))
        let used = CGFloat(columns) * xStride - gap + (columns > 1 ? xStride / 2 : 0)
        let insetX = max(gap, (width - min(used, width - gap)) / 2)
        return (0 ..< count).map { index in
            let row = index / columns
            let col = index % columns
            let stagger = row.isMultiple(of: 2) ? 0 : xStride / 2
            let x = insetX + CGFloat(col) * xStride + stagger
            let y = gap + CGFloat(row) * yStride
            return CGRect(x: x, y: y, width: hexWidth, height: hexHeight)
        }
    }
}
