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
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                button.topAnchor.constraint(equalTo: self.topAnchor),
                self.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                self.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])
        }

        do { // diskView
            diskView.translatesAutoresizingMaskIntoConstraints = false
            diskView.isHidden = true
            self.addSubview(diskView)

            NSLayoutConstraint.activate([
                diskView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                diskView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                diskView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
                diskView.heightAnchor.constraint(equalTo: diskView.widthAnchor),
            ])
        }
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
}

extension Disk {
    fileprivate var tintColor: UIColor {
        switch self {
        case .dark: return UIColor(named: "DarkColor")!
        case .light: return UIColor(named: "LightColor")!
        }
    }
}
