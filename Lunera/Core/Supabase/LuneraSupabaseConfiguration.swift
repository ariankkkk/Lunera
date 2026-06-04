import Foundation

struct LuneraSupabaseConfiguration: Equatable {
    let url: URL
    let publishableKey: String

    static func fromBundle(_ bundle: Bundle = .main) -> LuneraSupabaseConfiguration? {
        guard let urlString = bundle.object(forInfoDictionaryKey: "LUNERASupabaseURL") as? String,
              let url = URL(string: urlString),
              let publishableKey = bundle.object(forInfoDictionaryKey: "LUNERASupabasePublishableKey") as? String,
              !publishableKey.isEmpty else {
            return nil
        }

        return LuneraSupabaseConfiguration(url: url, publishableKey: publishableKey)
    }
}
