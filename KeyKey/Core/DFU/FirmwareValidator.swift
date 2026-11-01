import Foundation
import CryptoKit

public struct FirmwareValidationResult {
    public let isValid: Bool
    public let fileSize: Int
    public let sha256Hex: String
    public let errorMessage: String?
}

/// 韌體安全與防呆驗證器
public final class FirmwareValidator {
    public static let minFirmwareBytes = 512
    public static let maxFirmwareBytes = 64 * 1024 // 64 KB (WCH CH57x Flash 區塊限制)

    public static func validate(data: Data) -> FirmwareValidationResult {
        let size = data.count

        // 計算 SHA256
        let digest = SHA256.hash(data: data)
        let hashString = digest.compactMap { String(format: "%02x", $0) }.joined()

        if size < minFirmwareBytes {
            return FirmwareValidationResult(
                isValid: false,
                fileSize: size,
                sha256Hex: hashString,
                errorMessage: "韌體檔案過小 (\(size) 位元組)，請確認是否為完整韌體二進位檔案 (.bin)。"
            )
        }

        if size > maxFirmwareBytes {
            return FirmwareValidationResult(
                isValid: false,
                fileSize: size,
                sha256Hex: hashString,
                errorMessage: "韌體檔案過大 (\(size) 位元組)，超出晶片 Flash 限制 (最大 64 KB)。"
            )
        }

        return FirmwareValidationResult(
            isValid: true,
            fileSize: size,
            sha256Hex: hashString,
            errorMessage: nil
        )
    }
}
