//
//  APIController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 4/16/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum NetworkError: Error {
    case noAuth
    case badAuth
    case otherError
    case badData
    case noDecode
}

final class APIController {
    
    private let baseUrl = URL(string: "https://lambdaanimalspotter.vapor.cloud/api")!
    var bearer: Bearer?
    
    // create function for sign up
    func signUp(with user: User, completion: @escaping (Error?) -> ()) {
        let signUpURL = baseUrl.appendingPathComponent("users/signup")
        
        var request = URLRequest(url: signUpURL)
        
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            NSLog("Error encoding user data: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (_, response, error) in
            if let error = error {
                completion(error)
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                completion(NSError(domain: "", code: response.statusCode, userInfo: nil))
                return
            }
            
            completion(nil)
        }.resume()
        
    }
    
    // create function for sign in
    
    func signIn(with user: User, completion: @escaping (Error?) -> ()) {
        let signInURL = baseUrl.appendingPathComponent("users/login")
        
        var request = URLRequest(url: signInURL)
        
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            NSLog("Error encoding user data: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(error)
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                completion(NSError(domain: "", code: response.statusCode, userInfo: nil))
                return
            }
            
            guard let data = data else {
                completion(NSError())
                return
            }
            
            let decoder = JSONDecoder()
            do {
                self.bearer = try decoder.decode(Bearer.self, from: data)
            } catch {
                NSLog("Error decoding bearer object: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
        
    }
    
    // create function for fetching all animal names
    func fetchAllAnimalNames(completion: @escaping (Result<[String], NetworkError>) -> ()) {
        guard let bearer = bearer else {
            completion(.failure(.noAuth))
            return
        }
        
        let allAnimalsUrl = baseUrl.appendingPathComponent("animals/all")
        
        var request = URLRequest(url: allAnimalsUrl)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                NSLog("Error receiving animal name data: \(error)")
                completion(.failure(.otherError))
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 401 {
                completion(.failure(.badAuth))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let animalNames = try decoder.decode([String].self, from: data)
                completion(.success(animalNames))
            } catch {
                NSLog("Error decoding animal objects: \(error)")
                completion(.failure(.noDecode))
                return
            }
            
        }.resume()
    }
    
    // create function for fetching animal details
    func fetchDetails(for animalName: String, completion: @escaping (Result<Animal, NetworkError>) -> ()) {
        guard let bearer = bearer else {
            completion(.failure(.noAuth))
            return
        }
        
        let animalUrl = baseUrl.appendingPathComponent("animals/\(animalName)")
        
        var request = URLRequest(url: animalUrl)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                NSLog("Error receiving animal name data: \(error)")
                completion(.failure(.otherError))
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 401 {
                completion(.failure(.badAuth))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                let animal = try decoder.decode(Animal.self, from: data)
                completion(.success(animal))
            } catch {
                NSLog("Error decoding animal object: \(error)")
                completion(.failure(.noDecode))
                return
            }
            
        }.resume()
    }
    
    // create function to fetch image
}
