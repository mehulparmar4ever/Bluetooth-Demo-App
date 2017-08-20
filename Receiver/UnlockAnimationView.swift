//
//  UnlockAnimationView.swift
//  Receiver
//
//  Created by Pavel Kazantsev on 8/19/17.
//  Copyright © 2017 PaKaz.net. All rights reserved.
//

import UIKit

typealias SELF = UnlockAnimationView

private let strokeColor = UIColor.white
private let bgColor = UIColor.orange
private let lineWidth: CGFloat = 4.0

private let animationsDelay = 0.25

class UnlockAnimationView: UIView {

    private let lockBodyLayer: CAShapeLayer = configureLockBodyLayer()
    private let lockShackleLayer: CAShapeLayer = configureLockShackleLayer()
    private let switchBaseLayer: CAShapeLayer = configureSwitchBaseLayer()
    private let switchHandleLayer: CAShapeLayer = configureSwitchHandleLayer()

    init() {
        super.init(frame: .zero)

        backgroundColor = nil
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        UIView.animate(withDuration: 0.22) {
            self.backgroundColor = bgColor
        }
        layer.addSublayer(lockShackleLayer)
        layer.addSublayer(lockBodyLayer)
        lockBodyLayer.addSublayer(switchBaseLayer)
        switchBaseLayer.frame.origin = switchBaseLayer.centerPoint(in: lockBodyLayer)
        switchBaseLayer.addSublayer(switchHandleLayer)
        switchHandleLayer.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        switchHandleLayer.frame.origin = CGPoint(x: 0, y: -4)

        DispatchQueue.main.asyncAfter(deadline: .now() + animationsDelay) {
            self.addAnimations()
        }

        finishAnimation()
    }

    private func addAnimations() {

        let openAnimation = configureOpenShackleAnimation()
        openAnimation.delegate = self
        openAnimation.fillMode = kCAFillModeForwards
        openAnimation.isRemovedOnCompletion = false
        openAnimation.setValue("openShackle", forKey: "name")
        openAnimation.setValue(lockShackleLayer, forKey: "layer")
        openAnimation.beginTime = CACurrentMediaTime()

        lockShackleLayer.add(openAnimation, forKey: "fwd")

        let handleStretchAnimation = configureHandleStretchAnimation()
        handleStretchAnimation.fillMode = kCAFillModeBoth
        handleStretchAnimation.beginTime = CACurrentMediaTime()
        handleStretchAnimation.isRemovedOnCompletion = false
//        handleStretchAnimation.setValue("stretch", forKey: "name")
//        handleStretchAnimation.setValue(switchHandleLayer, forKey: "layer")

        let handleMoveAnimation = configureHandleMoveAnimation()
        handleMoveAnimation.fillMode = kCAFillModeForwards
        handleMoveAnimation.beginTime = CACurrentMediaTime() + handleStretchAnimation.duration
        handleMoveAnimation.isRemovedOnCompletion = false
//        handleMoveAnimation.setValue("move", forKey: "name")
//        handleMoveAnimation.setValue(switchHandleLayer, forKey: "layer")

        let handleColorAnimation = configureHandleColorAnimation()
        handleMoveAnimation.fillMode = kCAFillModeForwards
        handleColorAnimation.beginTime = CACurrentMediaTime() + handleStretchAnimation.duration
        handleColorAnimation.isRemovedOnCompletion = false
//        handleColorAnimation.setValue("color", forKey: "name")
//        handleColorAnimation.setValue(switchHandleLayer, forKey: "layer")

        let handleShrinkAnimation = configureHandleShrinkAnimation()
        handleMoveAnimation.fillMode = kCAFillModeForwards
        handleShrinkAnimation.beginTime = CACurrentMediaTime()
                                            + handleStretchAnimation.duration
                                            + handleMoveAnimation.duration
                                            - handleShrinkAnimation.duration
        handleShrinkAnimation.delegate = self
        handleShrinkAnimation.isRemovedOnCompletion = false
        handleShrinkAnimation.setValue("shrink", forKey: "name")
        handleShrinkAnimation.setValue(switchHandleLayer, forKey: "layer")

        switchHandleLayer.add(handleStretchAnimation, forKey: nil)
        switchHandleLayer.add(handleMoveAnimation, forKey: nil)
        switchHandleLayer.add(handleColorAnimation, forKey: nil)
        switchHandleLayer.add(handleShrinkAnimation, forKey: nil)
    }

    private func finishAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            UIView.animate(withDuration: 0.2) {
                self.alpha = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                self.backgroundColor = nil
                self.layer.sublayers = nil
                self.alpha = 1.0

                self.resetLayers()
            }
        }
    }

    private func resetLayers() {
        lockShackleLayer.transform = CATransform3DIdentity
        switchHandleLayer.fillColor = bgColor.cgColor
        switchHandleLayer.position.x = 0
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 300, height: 300)
    }

}

extension UnlockAnimationView: CAAnimationDelegate {

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let name = anim.value(forKey: "name") as? String,
            let animation = anim as? CABasicAnimation,
            let layer = anim.value(forKey: "layer") as? CAShapeLayer else { return }

        if flag && name == "shrink" {
            layer.position.x = 22
            layer.transform = CATransform3DIdentity
            layer.fillColor = strokeColor.cgColor
            layer.removeAllAnimations()
        }
        if flag && name == "openShackle", let targetValue = animation.toValue as? CATransform3D {
            layer.transform = targetValue
            layer.removeAllAnimations()
        }
    }
}

extension CALayer {
    func centerPoint(in superlayer: CALayer) -> CGPoint {
        return CGPoint(x: (superlayer.frame.width - frame.width) / 2,
                       y: (superlayer.frame.height - frame.height) / 2)
    }
}

// MARK: Initialization
private func configureLockBodyLayer() -> CAShapeLayer {
    let layer = CAShapeLayer()
    let size = CGSize(width: 160, height: 120)
    let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 18)

    layer.path = path.cgPath
    layer.lineWidth = lineWidth
    layer.strokeColor = strokeColor.cgColor
    layer.fillColor = bgColor.cgColor

    let origin = CGPoint(x: (300 - size.width) / 2, y: 140)
    layer.frame = CGRect(origin: origin, size: size)

    return layer
}
private func configureLockShackleLayer() -> CAShapeLayer {
    let width: CGFloat = 18.0
    let extRaduis: CGFloat = 56.0

    let layer = CAShapeLayer()
    let center = CGPoint(x: extRaduis, y: extRaduis)

    let path = UIBezierPath(arcCenter: center, radius: extRaduis, startAngle: .pi, endAngle: 0, clockwise: true)
    path.addLine(to: CGPoint(x: extRaduis * 2, y: extRaduis + 20))
    path.addLine(to: CGPoint(x: extRaduis * 2 - width, y: extRaduis + 20))
    path.addLine(to: CGPoint(x: extRaduis * 2 - width, y: extRaduis))
    path.addArc(withCenter: center, radius: extRaduis - width, startAngle: 0, endAngle: .pi, clockwise: false)
    path.close()

    layer.path = path.cgPath
    layer.lineWidth = lineWidth
    layer.strokeColor = strokeColor.cgColor
    layer.fillColor = bgColor.cgColor
    layer.anchorPoint = CGPoint(x: (extRaduis * 2 - width / 2) / (extRaduis * 2), y: (extRaduis + 15) / extRaduis)

    let size = CGSize(width: extRaduis * 2, height: extRaduis)
    let origin = CGPoint(x: (300 - size.width) / 2, y: 140 - extRaduis)
    layer.frame = CGRect(origin: origin, size: size)

    return layer
}

private func configureSwitchBaseLayer() -> CAShapeLayer {
    let layer = CAShapeLayer()
    let size = CGSize(width: 52, height: 22)
    let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 11)

    layer.path = path.cgPath
    layer.lineWidth = lineWidth
    layer.strokeColor = strokeColor.cgColor
    layer.fillColor = bgColor.cgColor

    layer.frame = CGRect(origin: .zero, size: size)

    return layer
}
private func configureSwitchHandleLayer() -> CAShapeLayer {
    let layer = CAShapeLayer()
    let size = CGSize(width: 30, height: 30)
    let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 15)

    layer.path = path.cgPath
    layer.lineWidth = lineWidth
    layer.strokeColor = strokeColor.cgColor
    layer.fillColor = bgColor.cgColor

    layer.frame = CGRect(origin: .zero, size: size)

    return layer
}

private func configureOpenShackleAnimation() -> CAAnimation {
    let anim = CASpringAnimation(keyPath: "transform")

    anim.fromValue = CATransform3DIdentity
    anim.toValue = CATransform3DMakeRotation(0.5, 0, 0, 1.0)
    anim.damping = 18
    anim.initialVelocity = 14
    anim.mass = 2.0
    anim.duration = anim.settlingDuration

    return anim
}
private func configureHandleStretchAnimation() -> CAAnimation {
    let anim = CABasicAnimation(keyPath: "transform")

    anim.fromValue = CATransform3DIdentity
    anim.toValue = CATransform3DMakeScale(1.2, 1.0, 1.0)
    anim.duration = 0.2

    return anim
}
private func configureHandleMoveAnimation() -> CAAnimation {
    let anim = CABasicAnimation(keyPath: "position.x")

    anim.fromValue = NSNumber(value: 0)
    anim.toValue = NSNumber(value: 22)
    anim.duration = 0.3

    return anim
}
private func configureHandleColorAnimation() -> CAAnimation {
    let anim = CABasicAnimation(keyPath: "fillColor")

    anim.fromValue = bgColor.cgColor
    anim.toValue = strokeColor.cgColor
    anim.duration = 0.3

    return anim
}
private func configureHandleShrinkAnimation() -> CAAnimation {
    let anim = CABasicAnimation(keyPath: "transform")

    anim.fromValue = CATransform3DMakeScale(1.2, 1.0, 1.0)
    anim.toValue = CATransform3DIdentity
    anim.duration = 0.1

    return anim
}
