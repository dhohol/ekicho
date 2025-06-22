import SwiftUI

// MARK: - LineListView
struct LineListView: View {
    @StateObject private var store = EkichoDataStore()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    LogoView()
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    ProgressComponent(progress: store.totalProgress)
                    
                    CompanyFilterView(store: store)
                    
                    LazyVStack(spacing: 20) {
                        ForEach(store.filteredLines) { line in
                            NavigationLink(destination: StationListView(line: line, store: store)) {
                                LineCardView(
                                    line: line,
                                    visitedCount: store.visitedStationCount(for: line)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

enum LogoShape {
    case circle
    case roundedRectangle
}

struct LogoItem: View {
    let text: String
    let shape: LogoShape
    let color: Color
    
    var body: some View {
        let frameSize: CGFloat = (shape == .circle) ? 52 : 48

        ZStack {
            // The outer colored shape
            switch shape {
            case .circle:
                Circle()
                    .fill(color)
            case .roundedRectangle:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color)
            }
            
            // The inner white shape, created by padding a smaller shape
            switch shape {
            case .circle:
                Circle()
                    .fill(Color.white)
                    .padding(5) // Thicker border for circles
            case .roundedRectangle:
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                    .padding(6) // Keep existing border for rectangles
            }

            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(width: frameSize, height: frameSize)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct LogoView: View {
    var body: some View {
        HStack(spacing: 8) {
            LogoItem(text: "E", shape: .circle, color: Color(hex: "#E60073"))
            LogoItem(text: "KI", shape: .roundedRectangle, color: Color(hex: "#00BB85"))
            LogoItem(text: "CH", shape: .roundedRectangle, color: Color(hex: "#F39700"))
            LogoItem(text: "Ō", shape: .circle, color: Color(hex: "#0079C2"))
        }
    }
}

// MARK: - ProgressComponent
struct ProgressComponent: View {
    let progress: ProgressInfo
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(progress.visitedCount) of \(progress.totalCount) stations visited")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(progress.percentage * 100))% complete")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress.percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.07), radius: 6, x: 0, y: 2)
    }
}

// MARK: - CompanyFilterView
struct CompanyFilterView: View {
    @ObservedObject var store: EkichoDataStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Filter by Company")
                .font(.headline)
                .foregroundColor(.primary)
                .padding([.leading, .trailing, .top])

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    CompanyFilterButton(
                        company: "All",
                        isSelected: store.selectedCompanies.count == store.allCompanies.count && !store.allCompanies.isEmpty,
                        action: {
                            store.toggleAllCompanies()
                        }
                    )

                    ForEach(store.allCompanies, id: \.self) { company in
                        CompanyFilterButton(
                            company: company,
                            isSelected: store.selectedCompanies.contains(company),
                            action: {
                                store.toggleCompany(company)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 12)
        .frame(height: 80)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.07), radius: 6, x: 0, y: 2)
    }
}

// MARK: - CompanyFilterButton
struct CompanyFilterButton: View {
    let company: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(company)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - LineCardView
struct LineCardView: View {
    let line: TrainLine
    let visitedCount: Int
    
    private var progress: Double {
        guard line.stationIDs.count > 0 else { return 0 }
        return Double(visitedCount) / Double(line.stationIDs.count)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            if let iconName = line.iconAssetName {
                if line.shape == "square" {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .padding(4)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .shadow(radius: 2)
                } else {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .padding(4) // Add spacing inside the 36x36 frame
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white)) // optional
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            } else {
                if line.shape == "square" {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(line.color)
                            .frame(width: 36, height: 36)
                            .shadow(radius: 2)
                        Text(line.symbol ?? "")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(line.color)
                            .frame(width: 36, height: 36)
                            .shadow(radius: 2)
                        Text(line.symbol ?? "")
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(line.name)
                    .font(.headline)
                Text("\(visitedCount) of \(line.stationIDs.count) stations visited")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView(value: progress)
                    .accentColor(line.color)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.black).opacity(0.07), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    LineListView()
} 
