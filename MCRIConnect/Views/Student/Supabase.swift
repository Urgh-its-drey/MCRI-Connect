//
//  Supabase.swift
//  MCRIConnect
//

import Foundation
import Supabase

enum SupabaseConfiguration {

    static let projectURL = URL(
        string: "https://jpheyjepufzlxkzvsjzj.supabase.co"
    )!

    static let publishableKey = "sb_publishable_GXyYld2USYKDANsUTMUwOw_SnZ-0TrU"
}

// Shared Supabase client used by AuthService.
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfiguration.projectURL,
    supabaseKey: SupabaseConfiguration.publishableKey
)
