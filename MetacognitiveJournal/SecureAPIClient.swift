//
//  SecureAPIClient.swift
//  MetacognitiveJournal
//
//  Created by Paul Thomas on 4/16/25.
//


import Foundation

class SecureAPIClient {
    private let baseURL: URL
    private let apiKey: String
    private let secretKey: String

    init(baseURL: URL, apiKey: String, secretKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.secretKey = secretKey
    }

    func makeRequest(
        endpoint: String,
        method: String,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            let error = NSError(domain: "APIClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid endpoint URL"])
            completion(nil, error)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.uppercased()
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let headers = headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }

        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
            } catch {
                completion(nil, error)
                return
            }
        }

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            completion(data, error)
        }

        task.resume()
    }
}
