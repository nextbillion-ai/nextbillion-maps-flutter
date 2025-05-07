//
//  RNMBImageUtils.swift
//  nb_maps_flutter
//
//  Created by mac on 30/05/2022.
//

enum RNMBImageUtils {
    static func createTempFile(_ image: UIImage) -> URL? {
        let fileID = UUID().uuidString
        let pathComponent = "Documents/rctngl-snapshot-\(fileID).jpeg"
        let filePath = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(pathComponent)

        guard let data = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert UIImage to JPEG data.")
            return nil
        }

        do {
            try data.write(to: filePath, options: [.atomic])
            return filePath
        } catch {
            print("Failed to write image data to disk: \(error)")
            return nil
        }
    }

    static func createBase64(_ image: UIImage) -> URL {
        let data = image.jpegData(compressionQuality: 1.0)
        let b64string: String = data!.base64EncodedString(options: [.endLineWithCarriageReturn])
        let result = "data:image/jpeg;base64,\(b64string)"
        return URL(string: result)!
    }
}
