//
//  M3uError.swift
//  M3U
//
//  Created by Hemin Won on 2022/5/1.
//  Copyright © 2022 HeminWon. All rights reserved.
//
//  https://en.wikipedia.org/wiki/M3U
//  https://datatracker.ietf.org/doc/html/rfc8216

import Foundation

enum PlaylistTag: String, CaseIterable {
    case EXTM3U = "#EXTM3U"
    case EXTENC = "#EXTENC:"
    case EXTINF = "#EXTINF:"
    case PLAYLIST = "#PLAYLIST:"
    case EXTGRP = "#EXTGRP:"
    case EXTALB = "#EXTALB:"
    case EXTART = "#EXTART:"
    case EXTGENRE = "#EXTGENRE"
    case EXTM3A = "#EXTM3A"
    case EXTBYT = "#EXTBYT:"
    case EXTBIN = "#EXTBIN:"
    case EXTIMG = "#EXTIMG:"
}

public struct ChannelProperty: Codable {
    public fileprivate(set) var tvg_id: String?
    public fileprivate(set) var tvg_logo: String?
    public fileprivate(set) var tvg_name: String?
    public fileprivate(set) var group_title: String?
    
    private enum CodingKeys : String, CodingKey {
        case tvg_id = "tvg-id", tvg_logo = "tvg-logo", tvg_name = "tvg-name", group_title = "group-title"
    }
}

public struct Playlist: Codable {
    public fileprivate(set) var name: String?
    public fileprivate(set) var channels: [Channel]?
    public fileprivate(set) var m3uExtend: [[String : String]]?
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
        let oriRows = m3ucontent.components(separatedBy:.newlines).filter { return $0.count > 0 }
        guard oriRows.count > 0 else {
            throw M3uError.invalidEXTM3U
        }
        let regexKeys = PlaylistTag.allCases.map({ "\($0.rawValue)" }).joined(separator: "|")
        let regex = "^(\(regexKeys))"
        let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
        let rows = oriRows.filter { row in
            let str = row.trimmingCharacters(in: .whitespaces)
            let matches = RE.matches(in: str, options: .reportProgress, range: NSRange(location: 0, length: str.count))
            if str.hasPrefix("#") {
                return matches.count > 0
            }
            else if str.count > 0 {
                return true
            }
            return false
        }
        
        guard rows.first!.hasPrefix(PlaylistTag.EXTM3U.rawValue) else {
            throw M3uError.invalidEXTM3U
        }
        var chanel = Channel()
        for row in rows {
            if row.hasPrefix(PlaylistTag.EXTM3U.rawValue) {
                _ = try self.parseEXTM3U(row)
            }
            else if row.hasPrefix(PlaylistTag.EXTINF.rawValue) {
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
    
    func keyValuePairs(equality: String) -> [String: String]? {
        let string = equality
        guard let range = string.range(of: "=") else {
            print(string)
            return nil
        }
        let oriK = string.prefix(upTo: range.lowerBound)
        let oriV = string.suffix(from: range.upperBound)
        let key = oriK.trimmingCharacters(in: .whitespaces)
        var processingValue = oriV.trimmingCharacters(in: .whitespaces)
        if processingValue.hasPrefix("\"") {processingValue.removeFirst()}
        if processingValue.hasSuffix("\"") {processingValue.removeLast()}
        let value = processingValue.trimmingCharacters(in: .whitespaces)
        guard key.count > 0, value.count > 0 else {
            return nil
        }
        return [key : value]
    }
    
    func parseEXTM3U(_ row: String) throws -> [String: String] {
        var retdict = [String: String]()
        // https://regex101.com/r/jMtkMd/1
        // /(\b\S+\s*=(\s*\".*?[^=]+\"\B|\S+))/gm
        let regexMap = "(\\b\\S+\\s*=(\\s*\".*?[^=]+\"\\B|\\S+))"
        let REMap = try NSRegularExpression(pattern: regexMap, options: .caseInsensitive)
        let matchesMap = REMap.matches(in: row, options: .reportProgress, range: NSRange(location: 0, length: row.count))
        for item in matchesMap {
            let string = (row as NSString).substring(with: item.range)
            if let keyValue = self.keyValuePairs(equality: string) {
                retdict = retdict.merging(keyValue) { (first, _) -> String in return first }
            }
        }
        return retdict
    }
    
    func parseProperties(row: String) throws -> [String: String] {
        // #EXTINF:<duration> [<attributes-list>], <title>
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
//        print(matchesMap.count)
        for item in matchesMap {
            let string = (row as NSString).substring(with: item.range)
            if let keyValue = self.keyValuePairs(equality: string) {
                retdict = retdict.merging(keyValue) { (first, _) -> String in return first }
            }
        }
        return retdict
    }
}
