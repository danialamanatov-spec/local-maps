import SwiftUI

struct CityPicker: View {
    @ObservedObject var app: AppState
    @StateObject private var dl = Downloader()
    @State private var query = ""

    private var filtered: [City] {
        query.isEmpty ? City.all : City.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Карта скачается один раз и дальше работает без интернета. Без аккаунтов, рекламы и трекеров.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                    ForEach(filtered) { row($0) }
                    if case .failed(let m) = dl.state {
                        Text(m).font(.footnote).foregroundStyle(.red).transition(.opacity)
                    }
                }
                .padding(16)
                .animation(.smooth, value: filtered)
            }
            .navigationTitle("Ваш город")
            .searchable(text: $query, prompt: "Поиск города")
            .onAppear { dl.onFinish = { app.choose($0) } }
        }
    }

    @ViewBuilder private func row(_ c: City) -> some View {
        let loading = dl.state == .loading(c.id)
        let have = LocalMaps.exists(c)
        Button {
            if have { app.choose(c) } else if !loading { dl.start(c) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "building.2.fill").font(.title3).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(.indigo, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).font(.headline).foregroundStyle(.primary)
                    Text(loading ? "Скачивание \(Int(dl.progress * 100))%" : have ? "Скачано — открыть" : c.region)
                        .font(.subheadline).foregroundStyle(.secondary).contentTransition(.numericText())
                }
                Spacer()
                if loading {
                    ZStack {
                        Circle().stroke(.quaternary, lineWidth: 4)
                        Circle().trim(from: 0, to: dl.progress)
                            .stroke(.indigo, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }.frame(width: 28, height: 28)
                } else {
                    Image(systemName: have ? "checkmark.circle.fill" : "arrow.down.circle")
                        .font(.title2).foregroundStyle(have ? .green : .indigo)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .animation(.smooth, value: dl.progress)
        .sensoryFeedback(.success, trigger: have)
    }
}
