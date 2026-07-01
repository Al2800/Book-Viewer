import CoreGraphics

struct CameraPreviewSizeStore {
    private var lastLayoutSize: CGSize?

    mutating func recordLayoutSize(_ size: CGSize) {
        guard Self.isValid(size) else { return }
        lastLayoutSize = size
    }

    func currentCroppingSize(previewLayerSize: CGSize?) -> CGSize? {
        if let previewLayerSize, Self.isValid(previewLayerSize) {
            return previewLayerSize
        }

        return lastLayoutSize
    }

    private static func isValid(_ size: CGSize) -> Bool {
        size.width > 0 && size.height > 0
    }
}
