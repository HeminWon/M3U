//
//  M3uError.swift
//  M3U
//
//  Created by Hemin Won on 2022/5/1.
//  Copyright © 2022 HeminWon. All rights reserved.
//

import Foundation

public struct ChannelProperty: Codable {
    public fileprivate(set) var tvg_id: String?
    public fileprivate(set) var tvg_logo: String?
    public fileprivate(set) var tvg_name: String?
    public fileprivate(set) var group_title: String?
}

public struct Channel: Codable {
    public fileprivate(set) var url: String?
    public fileprivate(set) var name: String?
    public fileprivate(set) var propMap: [String: String]?
    public fileprivate(set) var prop: ChannelProperty?
}

public struct M3U {
    public static func load(m3u: String) throws -> [Channel] {
        return try Parser.init(m3u:m3u).m3uToChannels()
    }

    public init() {
    }
}

public final class Parser {
    public let m3u: String
    
    var listach = [Channel]()
    
    public init(m3u string: String) throws {
        m3u = string
    }
    
    public func m3uToChannels() throws -> [Channel] {
        let rows = m3u.components(separatedBy:"\n").filter { return $0.count > 0 }
        guard rows.count > 0 else {
            throw M3uError.invalidEXTM3U
        }
        guard rows.first!.hasPrefix("#EXTM3U") else {
            throw M3uError.invalidEXTM3U
        }
        var chanel = Channel()
        for row in rows {
            if row.hasPrefix("#EXTM3U") {
                continue
            }
            else if row.hasPrefix("#EXT") {
                chanel.propMap = try self.parseProperties(row: row)
                chanel.name = self.parseName(row: row)
            }
            else if row.contains("://") {
                chanel.url = row.trimmingCharacters(in: .whitespaces)
                guard chanel.name != nil else {
                    continue
                }
                listach.append(chanel)
                chanel = Channel()
            }
        }
        guard listach.count > 0 else {
            throw M3uError.invalidEXTM3U
        }
        return listach
    }
    
    func parseName(row: String) -> String? {
        let sep = row.components(separatedBy: ",")
        guard sep.count == 2 else {
            return nil
        }
        guard let oriName = sep.last?.trimmingCharacters(in: .whitespaces) else {
            return nil
        }
        guard oriName.count > 0 else {
            return nil
        }
        return oriName
    }
    
    func parseProperties(row: String) throws -> [String: String] {
        var retdict = [String: String]()
        let regex = "#EXT.*:(-?\\d+)\\s(.*?=.*?)\\s?\\,\\s?(.*?$)"
        let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
        let matches = RE.matches(in: row, options: .reportProgress, range: NSRange(location: 0, length: row.count))
        print(matches.count)
        for item in matches {
            let string = (row as NSString).substring(with: item.range)
            print(string)
        }
        let xs = row.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\"", with: "").components(separatedBy: " ")
        for str in xs {
            let ixs = str.components(separatedBy: "=")
            guard ixs.count == 2 else {
                continue
            }
            guard let key = ixs.first, let value = ixs.last else {
                continue
            }
            guard key.count > 0, value.count > 0 else {
                continue
            }
            retdict[key] = value
        }
        return retdict
    }
}
