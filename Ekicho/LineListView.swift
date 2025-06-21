import SwiftUI

// MARK: - LineListView
struct LineListView: View {
    @StateObject private var store = EkichoDataStore()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Component
                ProgressComponent(progress: store.totalProgress)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Filter Component
                CompanyFilterView(store: store)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Lines List
                ScrollView(.vertical, showsIndicators: true) {
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
                    .padding(.vertical, 24)
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Ekicho")
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
