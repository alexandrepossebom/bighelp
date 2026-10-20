import Foundation
import Testing
@testable import Bighelp

/// Rows the session list must read, or skip on their own.
@MainActor
struct DirectHermesSessionCatalogRowTests {
    /// Text pasted from chat apps carries invisible format characters: a word joiner (U+2060) in a
    /// Matrix chat's preview hid every chat started after it, and a family emoji joins with U+200D.
    @Test func invisibleFormatCharactersInTitlesAndPreviewsStillList() async throws {
        let workspace = try SessionWorkspaceStub()
        var joined = try #require(DirectHermesSessionCatalogClientTests.session(id: "joined").object)
        joined["preview"] = .string("Ida \u{2060}27/10\u{2060} Curitiba")
        var family = try #require(DirectHermesSessionCatalogClientTests.session(id: "family").object)
        family["title"] = .string("Trip with 👨\u{200D}👩\u{200D}👧\u{FEFF}")
        workspace.handler = { operation, _ in
            switch operation {
            case .profilesList: return DirectHermesSessionCatalogClientTests.profiles()
            case .sessionsList: return DirectHermesSessionCatalogClientTests.ownershipPage([.object(joined), .object(family)])
            default: throw WorkspaceClientError.invalidRequest
            }
        }
        let records = try await DirectHermesSessionCatalogClientTests.client(workspace).list()
        #expect(records.count == 2)
        #expect(records.first { $0.remoteStoredID == "joined" }?.catalogPreview == "Ida \u{2060}27/10\u{2060} Curitiba")
        #expect(records.first { $0.remoteStoredID == "family" }?.title == "Trip with 👨\u{200D}👩\u{200D}👧\u{FEFF}")
    }

    @Test func controlCharactersStayRefusedInSessionText() throws {
        #expect(throws: WorkspaceClientError.invalidResponse) { try DirectHermesSessionValidation.text("bell\u{07}", maximum: 64) }
        #expect(throws: WorkspaceClientError.invalidResponse) { try DirectHermesSessionValidation.text("next\u{85}line", maximum: 64) }
        #expect(try DirectHermesSessionValidation.text("two\nlines\r\tok", maximum: 64) == "two\nlines\r\tok")
    }
}
