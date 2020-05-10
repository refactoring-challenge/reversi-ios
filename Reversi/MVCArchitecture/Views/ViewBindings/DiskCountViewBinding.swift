import ReversiCore
import ReactiveSwift



public class DiskCountViewBinding {
    private let (lifetime, token) = ReactiveSwift.Lifetime.make()
    private let diskCountModel: DiskCountModelProtocol
    private let diskCountViewHandle: DiskCountViewHandleProtocol


    public init(
        observing diskCountModel: DiskCountModelProtocol,
        updating diskCountViewHandle: DiskCountViewHandleProtocol
    ) {
        self.diskCountModel = diskCountModel
        self.diskCountViewHandle = diskCountViewHandle

        diskCountModel.diskCountDidChange
            .producer
            .take(during: self.lifetime)
            .observe(on: UIScheduler())
            .on(value: { [weak self] diskCount in
                self?.diskCountViewHandle.apply(diskCount: diskCount)
            })
            .start()
    }
}