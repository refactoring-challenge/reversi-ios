import UIKit

private let animationDuration: TimeInterval = 0.25

public class CellView: UIView {
    private let button: UIButton = UIButton()
    private let diskView: DiskView = DiskView()
    
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
            self.addSubview(diskView)
        }

        setNeedsLayout()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = bounds
        layoutDiskView()
    }
    
    private func layoutDiskView() {
        let cellSize = bounds.size
        let diskDiameter = Swift.min(cellSize.width, cellSize.height) * 0.8
        let diskSize: CGSize
        if _disk == nil || diskView.disk == _disk {
            diskSize = CGSize(width: diskDiameter, height: diskDiameter)
        } else {
            diskSize = CGSize(width: 0, height: diskDiameter)
        }
        diskView.frame = CGRect(
            origin: CGPoint(x: (cellSize.width - diskSize.width) / 2, y: (cellSize.height - diskSize.height) / 2),
            size: diskSize
        )
        diskView.alpha = _disk == nil ? 0.0 : 1.0
    }
    
    public func setDisk(_ disk: Disk?, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let diskBefore: Disk? = _disk
        _disk = disk
        let diskAfter: Disk? = _disk
        if animated {
            switch (diskBefore, diskAfter) {
            case (.none, .none):
                completion?(true)
            case (.none, .some(let animationDisk)):
                diskView.disk = animationDisk
                fallthrough
            case (.some, .none):
                UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseIn, animations: { [weak self] in
                    self?.layoutDiskView()
                }, completion: { finished in
                    completion?(finished)
                })
            case (.some, .some):
                UIView.animate(withDuration: animationDuration / 2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                    self?.layoutDiskView()
                }, completion: { [weak self] finished in
                    guard let self = self else { return }
                    if self.diskView.disk == self._disk {
                        completion?(finished)
                    }
                    guard let diskAfter = self._disk else {
                        completion?(finished)
                        return
                    }
                    self.diskView.disk = diskAfter
                    UIView.animate(withDuration: animationDuration / 2, animations: { [weak self] in
                        self?.layoutDiskView()
                    }, completion: { finished in
                        completion?(finished)
                    })
                })
            }
        } else {
            if let diskAfter = diskAfter {
                diskView.disk = diskAfter
            }
            completion?(true)
            setNeedsLayout()
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
