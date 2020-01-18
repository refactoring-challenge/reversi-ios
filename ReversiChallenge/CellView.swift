import UIKit

public class CellView: UIView {
    private let button: UIButton = UIButton()
    private let diskView: UIView = UIImageView(image: UIImage(systemName: "circle.fill")!)
    
    private var _disk: Disk?
    public var disk: Disk? {
        get { _disk }
        set { setDisk(newValue, animated: true) }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }
    
    private func setUp() {
        do { // button
            button.translatesAutoresizingMaskIntoConstraints = false
            do { // backgroundImage
                UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
                defer { UIGraphicsEndImageContext() }
                
                let color: UIColor = UIColor(named: "CellColor")!
                color.set()
                UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
                
                let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()!
                button.setBackgroundImage(backgroundImage, for: .normal)
                button.setBackgroundImage(backgroundImage, for: .disabled)
            }
            self.addSubview(button)
        }

        do { // diskView
            diskView.translatesAutoresizingMaskIntoConstraints = false
            diskView.isHidden = true
            self.addSubview(diskView)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = bounds
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.9
        diskView.frame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskDiameter) / 2, y: (cellSize.height - diskDiameter) / 2),
            size: CGSize(width: diskDiameter, height: diskDiameter)
        )
    }
    
    public func setDisk(_ disk: Disk?, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        if animated {
            // FIXME: Implement animations
            setDisk(disk, animated: false, completion: completion)
        } else {
            _disk = disk
            switch disk {
            case .none:
                diskView.isHidden = true
            case .some(let disk):
                diskView.tintColor = disk.tintColor
                diskView.isHidden = false
            }
            completion?(true)
        }
    }
    
    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }
    
    public func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        button.removeTarget(target, action: action, for: controlEvents)
    }
    
    public func actions(forTarget target: Any?, forControlEvent controlEvent: UIControl.Event) -> [String]? {
        button.actions(forTarget: target, forControlEvent: controlEvent)
    }
    
    public var allTargets: Set<AnyHashable> {
        button.allTargets
    }
    
    public var allControlEvents: UIControl.Event {
        button.allControlEvents
    }
}

extension Disk {
    fileprivate var tintColor: UIColor {
        switch self {
        case .dark: return UIColor(named: "DarkColor")!
        case .light: return UIColor(named: "LightColor")!
        }
    }
}
