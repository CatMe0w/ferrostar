import XCTest
@testable import FerrostarCore

final class MockURLSessionTests: XCTestCase {
    func testUninitializedSession() async throws {
        let session = MockURLSession()
        do {
            _ = try await session.loadData(with: URLRequest(url: URL(string: "https://example.com/")!))
            XCTFail("Expected an error")
        } catch MockURLSessionError.noResponseMockForMethodAndURL {
            // Expected failure
        }
    }

    func testMockedURL() async throws {
        let url = URL(string: "https://example.com/registered")!
        let mockData = Data("foobar".utf8)
        let mockResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!

        let session = MockURLSession()

        session.registerMock(forMethod: "GET", andURL: url, withData: mockData, andResponse: mockResponse)

        let (data, response) = try await session.loadData(with: URLRequest(url: url))
        XCTAssertEqual(data, mockData)
        XCTAssertEqual(response, mockResponse)

        do {
            _ = try await session.loadData(with: URLRequest(url: URL(string: "https://example.com/unregistered")!))
            XCTFail("Expected an error")
        } catch MockURLSessionError.noResponseMockForMethodAndURL {
            // Expected failure
        }
    }
}
