import Foundation

class PushEventUploader {

    static let shared = PushEventUploader()

    private let maxBatchSize = 500
    private let tdWriteKey = "YOUR_TD_WRITE_KEY" // Replace with your Treasure Data write-only API key
    private let tdDatabase = "mobile"
    private let tdTable = "push_events"
    private let tdEndpoint = "https://us01.records.in.treasuredata.com" // US01 region endpoint

    private var isUploading = false
    private let uploadQueue = DispatchQueue(label: "com.treasuredata.pushsample.uploader")

    private init() {}

    // MARK: - Upload

    func uploadEvents(completion: ((Bool) -> Void)? = nil) {
        uploadQueue.async {
            guard !self.isUploading else {
                print("⏳ Upload already in progress, skipping")
                completion?(false)
                return
            }

            let eventCount = EventQueue.shared.count()
            guard eventCount > 0 else {
                print("ℹ️ No events to upload")
                completion?(true)
                return
            }

            self.isUploading = true
            print("📤 Starting upload of \(eventCount) events")

            // Dequeue batch of events
            let events = EventQueue.shared.dequeue(count: self.maxBatchSize)

            self.sendToTreasureData(events: events) { success in
                self.isUploading = false

                if success {
                    print("✅ Successfully uploaded \(events.count) events")
                    completion?(true)

                    // If there are more events, upload next batch
                    if EventQueue.shared.count() > 0 {
                        self.uploadEvents()
                    }
                } else {
                    print("❌ Upload failed, re-enqueuing events")
                    // Re-enqueue events on failure
                    events.forEach { EventQueue.shared.enqueue(event: $0) }
                    completion?(false)
                }
            }
        }
    }

    // MARK: - Treasure Data API

    private func sendToTreasureData(events: [[String: Any]], completion: @escaping (Bool) -> Void) {
        let urlString = "\(tdEndpoint)/\(tdDatabase)/\(tdTable)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/vnd.treasuredata.v1+json", forHTTPHeaderField: "Content-Type")
        request.setValue("TD1 \(tdWriteKey)", forHTTPHeaderField: "Authorization")

        // Wrap events in "records" array for Data Ingestion API
        let payload: [String: Any] = ["records": events]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            print("❌ Error serializing payload: \(error)")
            completion(false)
            return
        }

        print("📡 Sending \(events.count) events to Treasure Data")
        print("URL: \(urlString)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                completion(false)
                return
            }

            print("📊 HTTP Status Code: \(httpResponse.statusCode)")

            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }

            if httpResponse.statusCode == 200 {
                completion(true)
            } else {
                print("❌ Upload failed with status code: \(httpResponse.statusCode)")
                completion(false)
            }
        }

        task.resume()
    }
}
