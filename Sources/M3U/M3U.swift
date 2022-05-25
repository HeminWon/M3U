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
    
    private enum CodingKeys : String, CodingKey {
        case tvg_id = "tvg-id", tvg_logo = "tvg-logo", tvg_name = "tvg-name", group_title = "group-title"
    }
}

public struct Channel: Codable {
    public fileprivate(set) var url: String?
    public fileprivate(set) var name: String?
    public fileprivate(set) var propMap: [String: String]?
    public fileprivate(set) var prop: ChannelProperty?
}

public struct M3U {
    public static func load(content: String) throws -> [Channel] {
        return try Parser.init(content:content).m3uToChannels()
    }
    
    public static func load(path: URL) throws -> [Channel] {
        return try Parser.init(path: path).m3uToChannels()
    }

    public init() {
    }
}

public final class Parser {
    public let m3ucontent: String
    
    var listach = [Channel]()
    
    public init(content: String) throws {
        m3ucontent = content
    }
    
    public init(path: URL) throws {
        let content = try String(contentsOf: path)
        m3ucontent = content
    }
    
    public func m3uToChannels() throws -> [Channel] {
        let rows = m3ucontent.components(separatedBy:"\n").filter { return $0.count > 0 }
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
                let json = try JSONSerialization.data(withJSONObject: chanel.propMap as Any)
                let prop = try JSONDecoder().decode(ChannelProperty.self, from: json)
                chanel.prop = prop
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
//        let regex = "#EXT.*:(-?\\d+)\\s(.*?=.*?)\\s?\\,\\s?(.*?$)"
//        let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
//        let matches = RE.matches(in: row, options: .reportProgress, range: NSRange(location: 0, length: row.count))
        // https://stackoverflow.com/questions/61346171/regex-match-between-last-occurrence-of-a-character-and-first-occurrence-of-anot
        /** (\b\S+\s*=\s*\".*?[^=]+\"\B) */
        // https://regex101.com/r/mvTU2O/1
        let regexMap = "(\\b\\S+\\s*=\\s*\".*?[^=]+\"\\B)"
        let REMap = try NSRegularExpression(pattern: regexMap, options: .caseInsensitive)
        let matchesMap = REMap.matches(in: row, options: .reportProgress, range: NSRange(location: 0, length: row.count))
        print(matchesMap.count)
        for item in matchesMap {
            let string = (row as NSString).substring(with: item.range)
            guard let range = string.range(of: "=") else {
                print(string)
                continue
            }
            let oriK = string.prefix(upTo: range.lowerBound)
            let oriV = string.suffix(from: range.upperBound)
            let key = oriK.trimmingCharacters(in: .whitespaces)
            var processingValue = oriV.trimmingCharacters(in: .whitespaces)
            if processingValue.hasPrefix("\"") {processingValue.removeFirst()}
            if processingValue.hasSuffix("\"") {processingValue.removeLast()}
            let value = processingValue.trimmingCharacters(in: .whitespaces)
            guard key.count > 0, value.count > 0 else {
                continue
            }
            retdict[key] = value
        }
        return retdict
    }
}
