import Foundation
import Supabase

enum SupabaseConfiguration {
    static let projectURL = URL(string: "https://jpheyjepufzlxkzvsjzj.supabase.co")!

    /// Publishable key: safe to ship in the binary, and only ever as powerful as the
    /// Row Level Security policies in supabase/schema.sql allow. A `service_role` key
    /// bypasses those policies and must never reach this file or the repository.
    static let publishableKey = "sb_publishable_GXyYld2USYKDANsUTMUwOw_SnZ-0TrU"

    /// Where a password-reset link lands. The custom scheme comes back to this app, so the
    /// token never passes through a web page; the same scheme must be added under
    /// Authentication → URL Parameters → Redirect URLs in the dashboard or Supabase ignores it.
    /// Declared as `CFBundleURLTypes` in Config/Info.plist so iOS routes it here.
    static let resetScheme = "mcri-connect"
    static let resetRedirect = URL(string: "\(resetScheme)://auth/reset")!
}

/// Shared client. Auth keeps its session in the Keychain, so every request carries the
/// signed-in token and PostgREST applies that token's role policies server-side.
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfiguration.projectURL,
    supabaseKey: SupabaseConfiguration.publishableKey
)

enum StorageBucket: String {
    case avatars
    case logos
    case cvs

    var isPublic: Bool { self != .cvs }
}

/// Resolves a stored object path to a loadable URL. Private objects (the cv bucket) are
/// fetched through the authenticated SDK rather than a public URL, so they return nil here.
func mcriImageURL(bucket: StorageBucket, path: String?) -> URL? {
    guard bucket.isPublic, let path, !path.isEmpty else { return nil }
    return SupabaseConfiguration.projectURL
        .appendingPathComponent("storage/v1/object/public/\(bucket.rawValue)/\(path)")
}

func mcriAvatarURL(_ path: String?) -> URL? { mcriImageURL(bucket: .avatars, path: path) }

func mcriLogoURL(_ path: String?) -> URL? { mcriImageURL(bucket: .logos, path: path) }
