import Foundation

struct CSVImporter {
    static func parse(csv: String) -> [SchoolEvent] {
        let rows = smartCSVRows(csv)
        guard let header = rows.first else { return [] }

        func idx(_ name: String) -> Int? { header.firstIndex { $0.caseInsensitiveCompare(name) == .orderedSame } }

        guard let cStartDate = idx("start_date"),
              let cFinishDate = idx("finish_date"),
              let cName = idx("name")
        else { return [] }

        let cStartTime = idx("start_time")
        let cFinishTime = idx("finish_time")
        let cAllDay = idx("all_day")
        let cLocation = idx("location")
        let cType = idx("event_type")
        let cDetail = idx("detail")

        let dfD = DateFormatter(); dfD.dateFormat = "dd/MM/yyyy"; dfD.locale = .init(identifier: "en_AU")
        let dfT = DateFormatter(); dfT.dateFormat = "HH:mm"; dfT.locale = .init(identifier: "en_AU")

        func combine(date d: String, time t: String?) -> Date? {
            guard let base = dfD.date(from: d) else { return nil }
            guard let t = t, let time = dfT.date(from: t) else { return base }
            var comps = Calendar.current.dateComponents([.year,.month,.day], from: base)
            let tcomps = Calendar.current.dateComponents([.hour,.minute], from: time)
            comps.hour = tcomps.hour; comps.minute = tcomps.minute
            return Calendar.current.date(from: comps)
        }

        func val(_ i: Int?, _ cols: [String]) -> String? { i.flatMap { $0 < cols.count ? cols[$0] : nil }?.nilIfEmpty() }

        return rows.dropFirst().compactMap { cols -> SchoolEvent? in
            guard let sd = val(cStartDate, cols),
                  let ed = val(cFinishDate, cols),
                  let title = val(cName, cols),
                  let start = combine(date: sd, time: val(cStartTime, cols)),
                  let end = combine(date: ed, time: val(cFinishTime, cols))
            else { return nil }

            let allDay = (val(cAllDay, cols) ?? "").lowercased() == "true"
            return SchoolEvent(
                title: title,
                start: start,
                end: end,
                location: val(cLocation, cols),
                category: val(cType, cols),
                detail: val(cDetail, cols),
                allDay: allDay
            )
        }
    }

    private static func smartCSVRows(_ text: String) -> [[String]] {
        var rows: [[String]] = [], row: [String] = []; var field = ""; var inQuotes = false
        func pushField() { row.append(field); field = "" }
        func pushRow() { rows.append(row); row = [] }
        for ch in text {
            if ch == "\"" { inQuotes.toggle() }
            else if ch == "," && !inQuotes { pushField() }
            else if (ch == "\n" || ch == "\r\n") && !inQuotes { pushField(); pushRow() }
            else { field.append(ch) }
        }
        pushField(); if !row.isEmpty { pushRow() }
        return rows.map { $0.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
    }
}

//private extension String { func nilIfEmpty() -> String? { //isEmpty ? nil : self } }
