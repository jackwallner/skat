import RevenueCat
import XCTest
@testable import SkatTrainer

final class PurchaseErrorCopyTests: XCTestCase {
    func testRevenueCatErrorsReadInGerman() {
        let cases: [(RevenueCat.ErrorCode, String)] = [
            (.paymentPendingError, "wartet auf Bestätigung"),
            (.networkError, "Keine Verbindung"),
            (.offlineConnectionError, "Keine Verbindung"),
            (.purchaseNotAllowedError, "nicht erlaubt"),
            (.storeProblemError, "App Store antwortet"),
            (.unknownBackendError, "nicht geklappt"),
        ]
        for (code, expected) in cases {
            let message = PurchaseErrorCopy.message(for: code)
            XCTAssertTrue(message.contains(expected), "\(code): \(message)")
            XCTAssertNotEqual(message, (code as NSError).localizedDescription)
        }
    }

    func testBridgedNSErrorStillMaps() {
        let bridged = RevenueCat.ErrorCode.networkError as NSError
        XCTAssertTrue(PurchaseErrorCopy.message(for: bridged).contains("Keine Verbindung"))
    }

    func testOwnErrorsKeepTheirCopy() {
        XCTAssertEqual(PurchaseErrorCopy.message(for: PurchaseError.productsUnavailable),
                       PurchaseError.productsUnavailable.localizedDescription)
    }
}
