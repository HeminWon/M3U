import XCTest
@testable import M3U

final class M3UTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        guard let str = Bundle.module.path(forResource: "test", ofType: "m3u") else {
            XCTAssert(false)
            return
        }
        
//        let url = URL(string: "http://epg.51zmt.top:8000/e.xml")!
//        let st =  try String(contentsOf: url)
        
        do {
            let chanel = try M3U.load(path: URL(fileURLWithPath: str))
            print(chanel)
            
        } catch {
            print(error)
        }
        XCTAssertEqual(URL(string: str)?.lastPathComponent, "test.m3u")
    }
    
    func testExample2() throws {
        guard let str = Bundle.module.path(forResource: "zho", ofType: "m3u") else {
            XCTAssert(false)
            return
        }
        do {
            let chanel = try M3U.load(path: URL(fileURLWithPath: str))
            print(chanel)
            
        } catch {
            print(error)
        }
        XCTAssertEqual(URL(string: str)?.lastPathComponent, "zho.m3u")
    }
    
}

#if XCODE_BUILD
// https://stackoverflow.com/questions/47177036/use-resources-in-unit-tests-with-swift-package-manager
extension Foundation.Bundle {
    
    /// Returns resource bundle as a `Bundle`.
    /// Requires Xcode copy phase to locate files into `ExecutableName.bundle`;
    /// or `ExecutableNameTests.bundle` for test resources
    static var module: Bundle = {
        var thisModuleName = "M3U"
        var url = Bundle.main.bundleURL
        
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            url = bundle.bundleURL.deletingLastPathComponent()
            thisModuleName = thisModuleName.appending("Tests")
        }
        
        url = url.appendingPathComponent("\(thisModuleName).bundle")
        
        guard let bundle = Bundle(url: url) else {
            fatalError("Foundation.Bundle.module could not load resource bundle: \(url.path)")
        }
        
        return bundle
    }()
    
    /// Directory containing resource bundle
    static var moduleDir: URL = {
        var url = Bundle.main.bundleURL
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            // remove 'ExecutableNameTests.xctest' path component
            url = bundle.bundleURL.deletingLastPathComponent()
        }
        return url
    }()
    
}
#endif
