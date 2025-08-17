//
// SupabaseLocalStorage.swift
// LifeManager
//
// Custom local storage to avoid keychain issues during testing
//

import Foundation
import Supabase

/// In-memory storage for Supabase auth tokens to avoid keychain popups
class SupabaseLocalStorage: AuthLocalStorage {
    private var storage: [String: Data] = [:]
    
    func store(key: String, value: Data) throws {
        storage[key] = value
    }
    
    func retrieve(key: String) throws -> Data? {
        return storage[key]
    }
    
    func remove(key: String) throws {
        storage.removeValue(forKey: key)
    }
}