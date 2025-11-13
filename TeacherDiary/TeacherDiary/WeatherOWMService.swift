//
//  WeatherOWMService.swift
//  TeacherDiary
//
//  Created by Trevor Elliott on 10/11/2025.
//


import Foundation
import CoreLocation

// MARK: - Weather (OpenWeatherMap 5-day / 3-hour)
final class WeatherOWMService {
    private let apiKey = "018d39a40e5362819f8aea8110b43804"

    struct OWMResponse: Decodable {
        let list: [Item]
        struct Item: Decodable {
            let dt: TimeInterval
            let main: Main
            let weather: [Weather]
            struct Main: Decodable { let temp: Double }
            struct Weather: Decodable { let id: Int }
        }
    }

    func fetch3hForecast(lat: Double, lon: Double) async throws -> [HourlyPoint] {
        var comps = URLComponents(string: "https://api.openweathermap.org/data/2.5/forecast")!
        comps.queryItems = [
            .init(name: "lat", value: String(lat)),
            .init(name: "lon", value: String(lon)),
            .init(name: "appid", value: apiKey),
            .init(name: "units", value: "metric")
        ]
        let url = comps.url!

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(OWMResponse.self, from: data)

        return decoded.list.map { item in
            HourlyPoint(
                time: Date(timeIntervalSince1970: item.dt),
                temperature: item.main.temp,
                code: item.weather.first?.id ?? 800
            )
        }
    }
}

// MARK: - Weather data + ViewModel

struct HourlyPoint: Hashable {
    let time: Date
    let temperature: Double
    let code: Int
}

struct TargetSlot: Hashable {
    let hour: Int
    let minute: Int
    let label: String
}

struct WeatherSlot: Hashable {
    let label: String
    let temp: Double
    let code: Int
}

// MARK: - Weather icon conversion
enum WeatherIcon {
    static func sfSymbolFromOWM(id: Int) -> String {
        switch id {
        case 200...232: return "cloud.bolt.rain"
        case 300...321: return "cloud.drizzle"
        case 500...504: return "cloud.rain"
        case 511: return "cloud.hail"
        case 520...531: return "cloud.heavyrain"
        case 600...622: return "cloud.snow"
        case 701, 741: return "cloud.fog"
        case 800: return "sun.max"
        case 801: return "cloud.sun"
        case 802: return "cloud.sun"
        case 803, 804: return "cloud"
        default: return "cloud"
        }
    }
}
