import UIKit

public final class RaceCarView: UIView {

    // MARK: - Life Cycle

    public override init(frame: CGRect) {
        super.init(frame: frame)

        topView.backgroundColor = .red
        addSubview(topView)

        bottomView.backgroundColor = .yellow
        addSubview(bottomView)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Properties

    public var topView: UIView = .init()

    public var bottomView: UIView = .init()

    // MARK: - UIView

    public override func layoutSubviews() {
        let subviewSize = bounds.height / 4

        topView.bounds.size = .init(width: subviewSize, height: subviewSize)
        topView.center = .init(
            x: bounds.minX + subviewSize,
            y: bounds.height / 3
        )

        bottomView.bounds.size = .init(width: subviewSize, height: subviewSize)
        bottomView.center = .init(
            x: bounds.minX + subviewSize,
            y: bounds.height * 2 / 3
        )
    }
}
