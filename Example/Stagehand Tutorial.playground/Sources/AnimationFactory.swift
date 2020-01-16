import Stagehand

public enum AnimationFactory {

    public static func makeBasicViewAnimation() -> Animation<UIView> {
        var animation = Animation<UIView>()

        animation.addKeyframe(for: \.alpha, at: 0, value: 1)
        animation.addKeyframe(for: \.alpha, at: 0.5, value: 0.5)
        animation.addKeyframe(for: \.alpha, at: 1, value: 1)

        animation.addKeyframe(for: \.transform, at: 0, value: .identity)
        animation.addKeyframe(for: \.transform, at: 0.5, value: .init(scaleX: 1.1, y: 1.1))
        animation.addKeyframe(for: \.transform, at: 1, value: .identity)

        return animation
    }

}
