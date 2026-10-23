import Foundation

/// Анонимная загрузка: эфемерная сессия, без cookie и кэша, без идентификаторов.
final class Downloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    enum State: Equatable { case idle, loading(String), failed(String) }
    @Published var state: State = .idle
    @Published var progress = 0.0
    var onFinish: ((City) -> Void)?
    private var current: City?
    private var task: URLSessionDownloadTask?

    private lazy var session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.waitsForConnectivity = true
        c.httpCookieAcceptPolicy = .never
        c.httpShouldSetCookies = false
        c.urlCache = nil
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c, delegate: self, delegateQueue: .main)
    }()

    func start(_ city: City) {
        guard task == nil else { return }
        current = city; progress = 0; state = .loading(city.id)
        task = session.downloadTask(with: city.url)
        task?.resume()
    }

    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didWriteData _: Int64,
                    totalBytesWritten w: Int64, totalBytesExpectedToWrite e: Int64) {
        if e > 0 { progress = Double(w) / Double(e) }
    }

    func urlSession(_ s: URLSession, downloadTask t: URLSessionDownloadTask, didFinishDownloadingTo loc: URL) {
        guard let city = current else { return }
        guard (t.response as? HTTPURLResponse)?.statusCode == 200 else {
            state = .failed("Сервер не отдал карту. Проверьте адрес."); return
        }
        var dest = LocalMaps.url(city)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: loc, to: dest)
            var v = URLResourceValues(); v.isExcludedFromBackup = true
            try? dest.setResourceValues(v)
        } catch { state = .failed("Не удалось сохранить файл.") }
    }

    func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let city = current; self.task = nil
        if let error {
            if (error as NSError).code != NSURLErrorCancelled { state = .failed("Не удалось скачать. Проверьте интернет.") }
            return
        }
        if case .failed = state { return }
        state = .idle
        if let city { onFinish?(city) }
    }
}
