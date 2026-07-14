import Foundation

/// Comprueba si hay una release más nueva en GitHub que la versión instalada
/// (`CFBundleShortVersionString`). Sin dependencias de terceros (nada de
/// Sparkle) — solo la API pública de GitHub, sin autenticación.
enum UpdateChecker {
    struct UpdateResult {
        let version: String
        let releaseURL: URL
    }

    private static let latestReleaseAPIURL = URL(
        string: "https://api.github.com/repos/Marti-Ferret/dofus-tabs-macos/releases/latest"
    )!

    /// Llama al completion en el hilo principal: con el resultado si hay una
    /// versión más nueva, o `nil` si ya está al día o la comprobación falla
    /// (sin conexión, límite de peticiones de GitHub, etc. — falla en silencio,
    /// no es crítico).
    static func checkForUpdate(completion: @escaping (UpdateResult?) -> Void) {
        var request = URLRequest(url: latestReleaseAPIURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, _, error in
            let result = Self.parseResult(data: data, error: error)
            DispatchQueue.main.async { completion(result) }
        }.resume()
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    private static func parseResult(data: Data?, error: Error?) -> UpdateResult? {
        guard error == nil, let data,
              let release = try? JSONDecoder().decode(GitHubRelease.self, from: data),
              let releaseURL = URL(string: release.htmlURL) else {
            return nil
        }

        let latestVersion = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName
        let currentVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"

        guard isVersion(latestVersion, newerThan: currentVersion) else { return nil }
        return UpdateResult(version: latestVersion, releaseURL: releaseURL)
    }

    /// Compara versión por componente numérico ("0.10.0" > "0.9.0"), no como
    /// texto — una comparación de strings directa fallaría en ese caso.
    private static func isVersion(_ a: String, newerThan b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        let count = max(aParts.count, bParts.count)

        for index in 0..<count {
            let aValue = index < aParts.count ? aParts[index] : 0
            let bValue = index < bParts.count ? bParts[index] : 0
            if aValue != bValue { return aValue > bValue }
        }
        return false
    }
}
