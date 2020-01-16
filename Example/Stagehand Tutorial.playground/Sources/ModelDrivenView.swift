import UIKit

public final class ModelDrivenView: UIView {

    // MARK: - Life Cycle

    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .red
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Types

    public struct Model {

        // MARK: - Life Cycle

        public init(
            backgroundColor: UIColor?
        ) {
            self.backgroundColor = backgroundColor
        }

        // MARK: - Public Properties

        public var backgroundColor: UIColor?

    }

    // MARK: - Public Properties

    public var currentModel: Model {
        return .init(
            backgroundColor: backgroundColor
        )
    }

    // MARK: - Public Methods

    public func apply(model: Model) {
        backgroundColor = model.backgroundColor
    }

}
