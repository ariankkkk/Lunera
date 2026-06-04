import Foundation
import Supabase

enum LuneraSupabaseClient {
    static let shared: SupabaseClient? = {
        guard let configuration = LuneraSupabaseConfiguration.fromBundle() else {
            return nil
        }

        return SupabaseClient(
            supabaseURL: configuration.url,
            supabaseKey: configuration.publishableKey
        )
    }()
}
