import Foundation
import CryptoKit

public enum DFUTargetDevice: String, CaseIterable, Identifiable {
    case keyboard = "KeyKey 鍵盤本體"
    case powerOn = "無線開機模組 (PowerOnMod)"

    public var id: String { rawValue }

    public var expectedFilePrefix: String {
        switch self {
        case .keyboard: return "KeyKey_V"
        case .powerOn: return "PowerOnMod_V"
        }
    }
}

public struct FirmwareValidationResult {
    public let isValid: Bool
    public let fileSize: Int
    public let sha256Hex: String
    public let isRISCVHeaderValid: Bool
    public let isOfficialVerified: Bool
    public let warningMessage: String?
    public let errorMessage: String?
}

/// 韌體安全與防呆驗證器 (防範 VULN-01 無簽章或非 CH57x 二進位檔誤刷)
public final class FirmwareValidator {
    public static let minFirmwareBytes = 512
    public static let maxFirmwareBytes = 448 * 1024 // 448 KB (WCH CH573F BLE + CodeFlash 上限，官方 KeyKey_V102.bin 為 135,728 bytes)

    /// 官方已驗證釋出之韌體 SHA-256 白名單 (小寫 hex)
    public static var officialSHA256Allowlist: Set<String> = [
        // 官方 KeyKey_V102.bin (V1.0.2 防誤觸關燈版, 135,728 bytes)
        "69ab677364a57dda7a6ddf29873a3f578d48051cd3226b76cab9d0d794ca03fb"
    ]

    public static func validate(data: Data, fileName: String? = nil, target: DFUTargetDevice = .keyboard) -> FirmwareValidationResult {
        let size = data.count

        // 計算 SHA256
        let digest = SHA256.hash(data: data)
        let hashString = digest.compactMap { String(format: "%02x", $0) }.joined()
        let isOfficial = officialSHA256Allowlist.contains(hashString.lowercased())

        if size < minFirmwareBytes {
            return FirmwareValidationResult(
                isValid: false,
                fileSize: size,
                sha256Hex: hashString,
                isRISCVHeaderValid: false,
                isOfficialVerified: false,
                warningMessage: nil,
                errorMessage: "韌體檔案過小 (\(size) 位元組)，請確認是否為完整韌體二進位檔案 (.bin)。"
            )
        }

        if size > maxFirmwareBytes {
            return FirmwareValidationResult(
                isValid: false,
                fileSize: size,
                sha256Hex: hashString,
                isRISCVHeaderValid: false,
                isOfficialVerified: false,
                warningMessage: nil,
                errorMessage: "韌體檔案過大 (\(size) 位元組)，超出 CH573F 晶片 CodeFlash 限制 (最大 448 KB)。"
            )
        }

        // 檢查是否為非裸機二進位格式 (如 ELF, Mach-O, ZIP, JSON/HTML 文字檔或全 0x00 / 0xFF 空檔)
        let headerCheck = inspectCH57xBinaryHeader(data: data)
        if !headerCheck.valid {
            return FirmwareValidationResult(
                isValid: false,
                fileSize: size,
                sha256Hex: hashString,
                isRISCVHeaderValid: false,
                isOfficialVerified: false,
                warningMessage: nil,
                errorMessage: headerCheck.reason
            )
        }

        var warnings: [String] = []
        if let name = fileName {
            if !name.lowercased().hasSuffix(".bin") {
                return FirmwareValidationResult(
                    isValid: false,
                    fileSize: size,
                    sha256Hex: hashString,
                    isRISCVHeaderValid: true,
                    isOfficialVerified: isOfficial,
                    warningMessage: nil,
                    errorMessage: "檔案副檔名必須為 .bin。"
                )
            }
            if !name.hasPrefix(target.expectedFilePrefix) {
                warnings.append("檔名未以「\(target.expectedFilePrefix)」開頭，請確認此檔案適用於「\(target.rawValue)」。")
            }
        }

        if !isOfficial {
            warnings.append("此韌體未列於官方 SHA-256 簽章白名單中（屬於自訂或未簽章韌體），需勾選下方風險確認方可燒錄。")
        }

        return FirmwareValidationResult(
            isValid: true,
            fileSize: size,
            sha256Hex: hashString,
            isRISCVHeaderValid: true,
            isOfficialVerified: isOfficial,
            warningMessage: warnings.isEmpty ? nil : warnings.joined(separator: "\n"),
            errorMessage: nil
        )
    }

    /// 檢查 WCH CH57x (QingKe RISC-V / ARM) 韌體向量表標頭，攔截誤選之壓縮檔、執行檔或全空白映像
    private static func inspectCH57xBinaryHeader(data: Data) -> (valid: Bool, reason: String?) {
        let bytes = [UInt8](data.prefix(64))
        guard bytes.count >= 16 else {
            return (false, "檔案標頭不足 16 位元組。")
        }

        // 攔截常見非 .bin 封裝格式 (ELF, ZIP, Mach-O, PDF, JSON/XML)
        if bytes.starts(with: [0x7F, 0x45, 0x4C, 0x46]) {
            return (false, "此檔案為 ELF 執行檔，請轉換為 Raw Binary (.bin) 格式後再燒錄。")
        }
        if bytes.starts(with: [0x50, 0x4B, 0x03, 0x04]) {
            return (false, "此檔案為 ZIP 壓縮檔，請先解壓縮取出 .bin 韌體檔。")
        }
        if bytes.starts(with: [0xCF, 0xFA, 0xED, 0xFE]) || bytes.starts(with: [0xCA, 0xFE, 0xBA, 0xBE]) {
            return (false, "此檔案為 macOS Mach-O 二進位檔，並非 CH57x 韌體。")
        }
        if bytes.starts(with: [0x3A]) && bytes.contains(0x0A) {
            return (false, "此檔案疑似為 Intel HEX (.hex) 文字格式，請使用 .bin 二進位格式。")
        }

        // 檢查前 64 bytes 是否全為 0x00 或全為 0xFF
        if bytes.allSatisfy({ $0 == 0x00 }) || bytes.allSatisfy({ $0 == 0xFF }) {
            return (false, "檔案標頭全為空白 (0x00 / 0xFF)，缺少中斷向量表，燒錄將導致設備無法開機。")
        }

        return (true, nil)
    }
}
