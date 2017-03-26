//
//  ViewController.swift
//  tvOS Sample
//
//  Created by Kazuhiro Hayashi on 3/26/17.
//  Copyright © 2017 Kazuhiro Hayashi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.frame.size.width = 800

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

class TextView: UITextView {
    
    lazy var moreLabel: UILabel = {
        let label = UILabel()
        label.text = "さらに表示"
        label.textColor = .gray
        label.font = self.font
        label.textAlignment = .center
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textContainer.lineBreakMode = .byTruncatingTail
        isScrollEnabled = false
        isUserInteractionEnabled = true
        isSelectable = true
        textContainer.maximumNumberOfLines = 5
        textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        translatesAutoresizingMaskIntoConstraints = true
        addSubview(moreLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sizeToFit()
        moreLabel.sizeToFit()
        do {
            let x = bounds.width - moreLabel.bounds.width - textContainerInset.right
            let y = bounds.height - moreLabel.bounds.height - textContainerInset.bottom
            moreLabel.frame.origin = CGPoint(x: x, y: y)
        }
        let exclusivePath = UIBezierPath(rect: moreLabel.frame)
        textContainer.exclusionPaths = [exclusivePath]
    }
}

class VisualEffectView: UIVisualEffectView, FocusEffectable {

    var focusEffect: FocusEffect = FocusEffect()

    override func awakeFromNib() {
        super.awakeFromNib()
        effect = nil
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if let item = context.nextFocusedItem as? VisualEffectView, item == self {
            coordinator.addCoordinatedAnimations({ [weak self] in
                self?.activateEffect(isActivated: true)
                self?.effect = UIBlurEffect(style: .light)
            }, completion: {})
        } else if let item = context.previouslyFocusedItem as? VisualEffectView, item == self {
            coordinator.addCoordinatedAnimations({ [weak self] in
                self?.activateEffect(isActivated: false)
                self?.effect = nil
            }, completion: {})
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.transform = .identity
        }) { (finish) in }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.2, animations: { [weak self, activatedScale = activatedScale] in
            self?.transform = activatedScale
        }) { (finish) in }
    }
}

struct FocusEffect {
    let motionEffectGroup: UIMotionEffectGroup = {
        let xTilt = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        
        xTilt.maximumRelativeValue = 7
        xTilt.minimumRelativeValue = -7
        
        let tiltAngle = CGFloat(2 * M_PI / 180)
        
        var minX = CATransform3DIdentity
        minX.m34 = 1.0 / 500
        minX = CATransform3DRotate(minX, -tiltAngle, 1, 0, 0)
        
        var maxX = CATransform3DIdentity
        maxX.m34 = minX.m34
        maxX = CATransform3DRotate(maxX, tiltAngle, 1, 0, 0)
        
        let verticalTiltEffect = UIInterpolatingMotionEffect(keyPath: "layer.transform", type: .tiltAlongVerticalAxis)
        verticalTiltEffect.minimumRelativeValue = NSValue(caTransform3D: maxX)
        verticalTiltEffect.maximumRelativeValue = NSValue(caTransform3D: minX)
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [xTilt, verticalTiltEffect]
        return motionEffectGroup
    }()
}

protocol FocusEffectable: class {
    var focusEffect: FocusEffect { get set }
    var activatedScale: CGAffineTransform { get }
    func activateShadow(isActivated: Bool)
    func activateEffect(isActivated: Bool)
}

extension FocusEffectable where Self: UIView {
    
    var activatedScale: CGAffineTransform {
        return CGAffineTransform(scaleX: 1.05, y: 1.05)
    }
    
    func activateShadow(isActivated: Bool) {
        if isActivated {
            layer.masksToBounds = false
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowRadius = 30
            layer.shadowOffset = CGSize(width: 0, height: 20)
            layer.shadowOpacity = 0.3
        } else {
            layer.masksToBounds = false
            layer.shadowColor = UIColor.clear.cgColor
            layer.shadowRadius = 0
            layer.shadowOffset = CGSize(width: 0, height: 0)
            layer.shadowOpacity = 0
        }
    }
    
    func activateEffect(isActivated: Bool) {
        if isActivated {
            transform = activatedScale
            activateShadow(isActivated: true)
            addMotionEffect(focusEffect.motionEffectGroup)
        } else {
            transform = .identity
            activateShadow(isActivated: false)
            removeMotionEffect(focusEffect.motionEffectGroup)
        }
    }
}
