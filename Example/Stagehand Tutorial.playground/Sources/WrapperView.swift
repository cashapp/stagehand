import UIKit

public final class WrapperView: UIView {

    // MARK: - Life Cycle

    public init(wrappedView: UIView, outset: CGFloat = 20) {
        self.wrappedView = wrappedView

        super.init(
            frame: .init(
                x: 0,
                y: 0,
                width: wrappedView.bounds.width + 2 * outset,
                height: wrappedView.bounds.height + 2 * outset
            )
        )

        addSubview(wrappedView)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let wrappedView: UIView

    // MARK: - UIView

    public override func layoutSubviews() {
        wrappedView.center = .init(x: bounds.midX, y: bounds.midY)
    }

}
