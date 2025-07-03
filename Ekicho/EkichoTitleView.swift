import SwiftUI

struct EkichoTitleView: View {
    let cityId: String?
    
    init(cityId: String? = nil) {
        self.cityId = cityId
    }
    
    var body: some View {
        VStack(spacing: 8) {
            LogoView()
            
            if let cityId = cityId {
                Text(cityName(for: cityId))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    private func cityName(for cityId: String) -> String {
        switch cityId.lowercased() {
        case "tokyo":
            return "Tokyo"
        case "osaka":
            return "Osaka"
        case "kyoto":
            return "Kyoto"
        case "nagoya":
            return "Nagoya"
        case "sapporo":
            return "Sapporo"
        case "fukuoka":
            return "Fukuoka"
        case "kobe":
            return "Kobe"
        case "yokohama":
            return "Yokohama"
        default:
            return cityId.capitalized
        }
    }
}

#if DEBUG
struct EkichoTitleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            EkichoTitleView()
            EkichoTitleView(cityId: "tokyo")
            EkichoTitleView(cityId: "osaka")
        }
        .padding()
    }
}
#endif 