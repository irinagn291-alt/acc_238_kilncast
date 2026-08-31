import SwiftUI
import UIKit

/// Role: Presentation. Owns the collection, hex layout, and cell registration.
struct KilnWallRepresentable: UIViewRepresentable {
    var bricks: [BrickHeat]
    var onSelect: (UUID) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UICollectionView {
        let layout = HexKilnLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = true
        view.showsVerticalScrollIndicator = false
        view.isScrollEnabled = false
        view.delegate = context.coordinator
        view.dataSource = context.coordinator
        view.register(BrickCell.self, forCellWithReuseIdentifier: BrickCell.reuseID)
        view.accessibilityIdentifier = "kiln-wall"
        context.coordinator.bricks = bricks
        context.coordinator.onSelect = onSelect
        return view
    }

    func updateUIView(_ view: UICollectionView, context: Context) {
        let changed = context.coordinator.bricks != bricks
        context.coordinator.bricks = bricks
        context.coordinator.onSelect = onSelect
        if changed {
            view.reloadData()
        }
        view.collectionViewLayout.invalidateLayout()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        var bricks: [BrickHeat] = []
        var onSelect: (UUID) -> Void = { _ in }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            bricks.count
        }

        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: BrickCell.reuseID,
                for: indexPath
            )
            if let brick = bricks[safe: indexPath.item], let brickCell = cell as? BrickCell {
                brickCell.apply(brick)
            }
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let brick = bricks[safe: indexPath.item] else { return }
            onSelect(brick.person.id)
        }
    }
}

/// Role: Presentation. Sizes the hex wall from layout measure. No UIScreen.
struct KilnWallHost: View {
    var bricks: [BrickHeat] = []
    var onSelect: (UUID) -> Void = { _ in }
    @State private var width: CGFloat = 320

    var body: some View {
        KilnWallRepresentable(bricks: bricks, onSelect: onSelect)
            .frame(height: max(HexKilnLayout.measure(count: bricks.count, width: width), 1))
            .background {
                GeometryReader { geo in
                    Color.clear.preference(key: KilnWidthKey.self, value: geo.size.width)
                }
            }
            .onPreferenceChange(KilnWidthKey.self) { width = $0 }
    }
}

private struct KilnWidthKey: PreferenceKey {
    static var defaultValue: CGFloat { 320 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
