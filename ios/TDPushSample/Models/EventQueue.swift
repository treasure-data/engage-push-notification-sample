import Foundation

class EventQueue {

    static let shared = EventQueue()

    private let maxQueueSize = 1000
    private let queueKey = "td_push_event_queue"
    private let queue = DispatchQueue(label: "com.treasuredata.pushsample.eventqueue", attributes: .concurrent)

    private init() {}

    // MARK: - Queue Operations

    func enqueue(event: [String: Any]) {
        queue.async(flags: .barrier) {
            var events = self.loadEvents()

            // Add new event
            events.append(event)

            // Enforce max queue size (FIFO)
            if events.count > self.maxQueueSize {
                events.removeFirst(events.count - self.maxQueueSize)
                print("⚠️ Event queue exceeded max size, oldest events removed")
            }

            self.saveEvents(events)
            print("✅ Event enqueued. Total events: \(events.count)")
        }
    }

    func dequeue(count: Int) -> [[String: Any]] {
        var dequeuedEvents: [[String: Any]] = []

        queue.sync(flags: .barrier) {
            var events = self.loadEvents()

            let dequeueCount = min(count, events.count)
            dequeuedEvents = Array(events.prefix(dequeueCount))

            events.removeFirst(dequeueCount)
            self.saveEvents(events)

            print("📤 Dequeued \(dequeueCount) events. Remaining: \(events.count)")
        }

        return dequeuedEvents
    }

    func count() -> Int {
        var count = 0
        queue.sync {
            count = self.loadEvents().count
        }
        return count
    }

    func clear() {
        queue.async(flags: .barrier) {
            UserDefaults.standard.removeObject(forKey: self.queueKey)
            UserDefaults.standard.synchronize()
            print("🗑️ Event queue cleared")
        }
    }

    // MARK: - Persistence

    private func loadEvents() -> [[String: Any]] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            return []
        }

        do {
            if let events = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                return events
            }
        } catch {
            print("❌ Error loading events from queue: \(error)")
        }

        return []
    }

    private func saveEvents(_ events: [[String: Any]]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: events, options: [])
            UserDefaults.standard.set(data, forKey: queueKey)
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ Error saving events to queue: \(error)")
        }
    }
}
