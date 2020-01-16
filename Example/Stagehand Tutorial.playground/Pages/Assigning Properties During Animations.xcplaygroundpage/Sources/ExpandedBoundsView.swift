import UIKit

public final class ExpandedBoundsView: UIView {

    // MARK: - Life Cycle

    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .red

        bigSubview.backgroundColor = .green
        addSubview(bigSubview)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Properties

    private let bigSubview: UIView = .init()

    // MARK: - UIView

    public override func layoutSubviews() {
        bigSubview.bounds.size = bounds.insetBy(dx: -20, dy: 10).size
        bigSubview.center = .init(x: bounds.midX, y: bounds.midY)
    }

}
