import Flutter
import UIKit
import Photos

enum MediaType: Int {
    case image
    case video
}

public class SwiftGallerySaverPlugin: NSObject, FlutterPlugin {
    let path = "path"
    let albumName = "albumName"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "gallery_saver", binaryMessenger: registrar.messenger())
        let instance = SwiftGallerySaverPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "saveImage" {
            self.saveMedia(call, .image, result)
        } else if call.method == "saveVideo" {
            result(FlutterMethodNotImplemented)
//            self.saveMedia(call, .video, result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Tries to save image to the photos app.
    /// If user hasn't already permitted saving to the photos, it will be requested
    /// to do so.
    ///
    /// - Parameters:
    ///   - call: method object with params for saving media
    ///   - mediaType: media type
    ///   - result: flutter result that gets sent back to the dart code
    ///
    func saveMedia(_ call: FlutterMethodCall, _ mediaType: MediaType, _ result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        let path = args![self.path] as! String
        let albumName = args![self.albumName] as? String
//        _saveMediaToAlbum(path, mediaType, albumName, result)
        saveFile(path, mediaType, nil, result)
    }
    
    private func _saveMediaToAlbum(_ imagePath: String, _ mediaType: MediaType, _ albumName: String?,
                                   _ flutterResult: @escaping FlutterResult) {
        NSLog("saveMediaToAlbum: path=[\(imagePath)]")
        let fileUrl = URL(fileURLWithPath: imagePath)
        let imageData = NSData(contentsOf: fileUrl)
        NSLog("saveMediaToAlbum: fileUrl=[\(fileUrl.absoluteString)], imageData=\(imageData != nil)")
        let image = UIImage.init(data: imageData! as Data)
        guard let savableImage = image else {
            flutterResult(FlutterError(code: "Error when reading file", message: nil, details: nil))
            return
        }
        
        let responder = SaveImageResultHandler(result: flutterResult)
        UIImageWriteToSavedPhotosAlbum(savableImage, responder, #selector(SaveImageResultHandler.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    private func saveFile(_ filePath: String, _ mediaType: MediaType, _ album: PHAssetCollection?,
                          _ flutterResult: @escaping FlutterResult) {
        let url = URL(fileURLWithPath: filePath)
        PHPhotoLibrary.shared().performChanges({
            let assetCreationRequest = mediaType == .image ?
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            : PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url);
            if (album != nil) {
                guard let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: album!),
                      let createdAssetPlaceholder = assetCreationRequest?.placeholderForCreatedAsset else {
                    return
                }
                assetCollectionChangeRequest.addAssets(NSArray(array: [createdAssetPlaceholder]))
            }
        }) { (success, error) in
            if success {
                flutterResult(true)
            } else {
                flutterResult(false)
            }
        }
    }
//
//    private func fetchAssetCollectionForAlbum(_ albumName: String) -> PHAssetCollection? {
//        let fetchOptions = PHFetchOptions()
//        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
//        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
//
//        if let _: AnyObject = collection.firstObject {
//            return collection.firstObject
//        }
//        return nil
//    }
//
//    private func createAppPhotosAlbum(albumName: String, completion: @escaping (Error?) -> ()) {
//        PHPhotoLibrary.shared().performChanges({
//            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
//        }) { (_, error) in
//            DispatchQueue.main.async {
//                completion(error)
//            }
//        }
//    }
}

@objc class SaveImageResultHandler: NSObject {
    
    let result: FlutterResult
    
    init(result: @escaping FlutterResult) {
        self.result = result
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            NSLog("saveImage: error = \(error)")
            result(FlutterError(code: "Error saving file", message: nil, details: nil))
        } else {
            NSLog("saveImage: success")
            result(nil)
        }
    }
}

