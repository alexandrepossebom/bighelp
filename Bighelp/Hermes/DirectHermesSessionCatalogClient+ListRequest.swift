import Foundation

/// The list request: its options and when the pages end.
extension DirectHermesSessionCatalogClient {
    static func pageHasMore(_ page: [String: BighelpJSONValue], offset: Int, rows: Int) -> Bool {
        if let hasMore = page["has_more"]?.boolean { return hasMore }
        let limit = page["limit"]?.integer ?? 100
        if let total = page["total"]?.integer { return offset + limit < total }
        return rows >= limit
    }

    func validate(_ options: DirectHermesSessionListOptions) throws {
        guard options.sources.count <= 32, options.excludedSources.count <= 32 else {
            throw WorkspaceClientError.invalidRequest
        }
        for source in options.sources + options.excludedSources {
            try DirectHermesSessionValidation.coordinate(source, maximum: 128)
            guard !source.contains(",") else { throw WorkspaceClientError.invalidRequest }
        }
        if let path = options.cwdPrefix { try DirectHermesSessionValidation.hostPath(path) }
    }
}
