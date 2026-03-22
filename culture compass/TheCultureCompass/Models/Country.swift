import Foundation

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
    let region: String

    static let all: [Country] = [
        Country(name: "Ghana", code: "GH", flag: "🇬🇭", region: "West Africa"),
        Country(name: "Nigeria", code: "NG", flag: "🇳🇬", region: "West Africa"),
        Country(name: "South Africa", code: "ZA", flag: "🇿🇦", region: "Southern Africa"),
        Country(name: "Kenya", code: "KE", flag: "🇰🇪", region: "East Africa"),
        Country(name: "Tanzania", code: "TZ", flag: "🇹🇿", region: "East Africa"),
        Country(name: "Morocco", code: "MA", flag: "🇲🇦", region: "North Africa"),
        Country(name: "Egypt", code: "EG", flag: "🇪🇬", region: "North Africa"),
        Country(name: "Ethiopia", code: "ET", flag: "🇪🇹", region: "East Africa"),
        Country(name: "Senegal", code: "SN", flag: "🇸🇳", region: "West Africa"),
        Country(name: "Jamaica", code: "JM", flag: "🇯🇲", region: "Caribbean"),
        Country(name: "Barbados", code: "BB", flag: "🇧🇧", region: "Caribbean"),
        Country(name: "Trinidad and Tobago", code: "TT", flag: "🇹🇹", region: "Caribbean"),
        Country(name: "Brazil", code: "BR", flag: "🇧🇷", region: "South America"),
        Country(name: "Colombia", code: "CO", flag: "🇨🇴", region: "South America"),
        Country(name: "United Kingdom", code: "GB", flag: "🇬🇧", region: "Europe"),
        Country(name: "France", code: "FR", flag: "🇫🇷", region: "Europe"),
        Country(name: "Portugal", code: "PT", flag: "🇵🇹", region: "Europe"),
        Country(name: "Japan", code: "JP", flag: "🇯🇵", region: "Asia"),
        Country(name: "Thailand", code: "TH", flag: "🇹🇭", region: "Asia"),
        Country(name: "Mexico", code: "MX", flag: "🇲🇽", region: "North America"),
        Country(name: "Costa Rica", code: "CR", flag: "🇨🇷", region: "Central America"),
        Country(name: "Dominican Republic", code: "DO", flag: "🇩🇴", region: "Caribbean"),
        Country(name: "Bahamas", code: "BS", flag: "🇧🇸", region: "Caribbean"),
        Country(name: "Rwanda", code: "RW", flag: "🇷🇼", region: "East Africa"),
        Country(name: "Mozambique", code: "MZ", flag: "🇲🇿", region: "Southern Africa"),
    ]
}
