import SwiftUI

struct HomeView: View {
    @State private var showStartReview = false
    @State private var showConsumeBottle = false
    @State private var showAddWine = false
    @StateObject private var statsViewModel = HomeStatsViewModel()

    /// Bei Bedarf anpassen, falls die App mal von jemand anderem genutzt wird
    private let userName = "Alexander"

    private let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(greeting), \(userName)")
                            .font(.system(size: 24, weight: .bold))
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    if !statsViewModel.runningLowWines.isEmpty {
                        runningLowSection
                    }

                    LazyVGrid(columns: columns, spacing: 20) {
                        NavigationLink {
                            WineListView()
                        } label: {
                            HomeTile(title: "My Wine Cellar", systemImage: "wineglass.fill", color: .accentColor)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showAddWine = true
                        } label: {
                            HomeTile(title: "Add Wine", systemImage: "plus.circle.fill", color: .mint)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showConsumeBottle = true
                        } label: {
                            HomeTile(title: "Drink a Bottle", systemImage: "wineglass", color: .red)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showStartReview = true
                        } label: {
                            HomeTile(title: "Start a Review", systemImage: "star.fill", color: .orange)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            WineSearchView()
                        } label: {
                            HomeTile(title: "Wine Search", systemImage: "magnifyingglass", color: .indigo)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ReviewOverviewView()
                        } label: {
                            HomeTile(title: "Review Overview", systemImage: "list.bullet.rectangle.portrait", color: .teal)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            StatisticsView()
                        } label: {
                            HomeTile(title: "Statistics", systemImage: "chart.bar.fill", color: .green)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }

                statsBar
            }
            .background(Color("AppBackground"))
            .navigationTitle("Wine Cellar")
            .sheet(isPresented: $showStartReview) {
                StartReviewView {}
            }
            .sheet(isPresented: $showConsumeBottle) {
                ConsumeBottleView {
                    Task { await statsViewModel.load() }
                }
            }
            .sheet(isPresented: $showAddWine) {
                NewWineView {
                    Task { await statsViewModel.load() }
                }
            }
            .task {
                await statsViewModel.load()
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }

    private var runningLowSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Running Low")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(statsViewModel.runningLowWines) { wine in
                        NavigationLink {
                            WineDetailView(wine: wine) {
                                Task { await statsViewModel.load() }
                            }
                        } label: {
                            RunningLowCard(wine: wine)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 16)
    }

    private var statsBar: some View {
        HStack(spacing: 0) {
            HomeStatItem(
                value: "\(statsViewModel.totalBottles)",
                label: "Bottles in stock",
                systemImage: "wineglass.fill",
                color: .accentColor
            )
            Divider().frame(height: 36)
            HomeStatItem(
                value: "\(statsViewModel.drunkLast30Days)",
                label: "Drunk (30 days)",
                systemImage: "calendar",
                color: .orange
            )
        }
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

private struct RunningLowCard: View {
    let wine: Wine

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                Text("\(wine.currentQuantity) left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            Text(wine.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(width: 130, alignment: .leading)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct HomeStatItem: View {
    let value: String
    let label: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeTile: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 64, height: 64)
                Image(systemName: systemImage)
                    .font(.system(size: 26))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(0.95, contentMode: .fill)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

#Preview {
    HomeView()
}
