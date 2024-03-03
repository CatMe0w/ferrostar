import CoreLocation
@testable import class FerrostarCore.MockURLSession
import class FerrostarCore.SimulatedLocationProvider
import enum FerrostarCore.FerrostarCoreError
import protocol FerrostarCore.FerrostarCoreDelegate
import enum FerrostarCore.CorrectiveAction
import class FerrostarCore.FerrostarCore
import struct FerrostarCore.NavigationControllerConfig
import FerrostarCoreFFI
import XCTest
import SnapshotTesting

let errorBody = Data("""
{
    "error": "No valid authentication provided."
}
""".utf8)
let errorResponse = HTTPURLResponse(url: valhallaEndpointUrl, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!

// Mocked route
let mockGeom = [GeographicCoordinate(lat: 0, lng: 0), GeographicCoordinate(lat: 1, lng: 1)]
let instructionContent = VisualInstructionContent(text: "Sail straight", maneuverType: .depart, maneuverModifier: .straight, roundaboutExitDegrees: nil)
let mockRoute = Route(geometry: mockGeom, bbox: BoundingBox(sw: mockGeom.first!, ne: mockGeom.last!), distance: 1, waypoints: mockGeom.map { Waypoint(coordinate: $0, kind: .break) }, steps: [RouteStep(geometry: mockGeom, distance: 1, roadName: "foo road", instruction: "Sail straight", visualInstructions: [VisualInstruction(primaryContent: instructionContent, secondaryContent: nil, triggerDistanceBeforeManeuver: 42)], spokenInstructions: [])])

// Mocked route adapter
let mockRouteAdapter = RouteAdapter(requestGenerator: MockRouteRequestGenerator(), responseParser: MockRouteResponseParser(routes: [mockRoute]))

private class MockRouteRequestGenerator: RouteRequestGenerator {
    func generateRequest(userLocation: UserLocation, waypoints: [Waypoint]) throws -> RouteRequest {
        return RouteRequest.httpPost(url: valhallaEndpointUrl.absoluteString, headers: [:], body: Data())
    }
}

private class MockRouteResponseParser: RouteResponseParser {
    private let routes: [Route]

    init(routes: [Route]) {
        self.routes = routes
    }

    func parseResponse(response: Data) throws -> [Route] {
        return routes
    }
}


final class FerrostarCoreTests: XCTestCase {
    func test401UnauthorizedRouteResponse() async throws {
        let mockSession = MockURLSession()
        mockSession.registerMock(forURL: valhallaEndpointUrl, withData: errorBody, andResponse: errorResponse)

        let routeAdapter = RouteAdapter(requestGenerator: MockRouteRequestGenerator(), responseParser: MockRouteResponseParser(routes: []))

        let core = FerrostarCore(routeAdapter: routeAdapter, locationProvider: SimulatedLocationProvider(), networkSession: mockSession)

        do {
            // Tests that the core generates a request and attempts to process it, but throws due to the mocked network layer
            _ = try await core.getRoutes(initialLocation: CLLocation(latitude: 60.5347155, longitude: -149.543469), waypoints: [Waypoint(coordinate: GeographicCoordinate(lat: 60.5349908, lng: -149.5485806), kind: .break)])
            XCTFail("Expected an error")
        } catch let FerrostarCoreError.httpStatusCode(statusCode) {
            XCTAssertEqual(statusCode, 401)
        }
    }

    @MainActor
    func test200MockRouteResponse() async throws {
        let mockSession = MockURLSession()
        mockSession.registerMock(forURL: valhallaEndpointUrl, withData: Data(), andResponse: successfulJSONResponse)

        let core = FerrostarCore(routeAdapter: mockRouteAdapter, locationProvider: SimulatedLocationProvider(), networkSession: mockSession)

        // Tests that the core generates a request and then the mocked parser returns the expected routes
        let routes = try await core.getRoutes(initialLocation: CLLocation(latitude: 60.5347155, longitude: -149.543469), waypoints: [Waypoint(coordinate: GeographicCoordinate(lat: 60.5349908, lng: -149.5485806), kind: .break)])
        assertSnapshot(of: routes, as: .dump)
    }

    func testCustomRouteDeviationHandler() async throws {
        let routeDeviationCallbackExp = expectation(description: "The delegate should receive a callback that the user has deviated from the route")
        routeDeviationCallbackExp.expectedFulfillmentCount = 1

        let loadedAltRoutesExp = expectation(description: "The delegate should receive a callback when alternative routes are loaded")
        loadedAltRoutesExp.expectedFulfillmentCount = 1

        let locationProvider = SimulatedLocationProvider()
        
        let mockSession = MockURLSession()
        mockSession.registerMock(forURL: valhallaEndpointUrl, withData: Data(), andResponse: successfulJSONResponse)

        let core = FerrostarCore(routeAdapter: mockRouteAdapter, locationProvider: locationProvider, networkSession: mockSession)

        class CoreDelegate: FerrostarCoreDelegate {
            private let routeDeviationCallbackExp: XCTestExpectation
            private let loadedAltRoutesExp: XCTestExpectation

            init(routeDeviationCallbackExp: XCTestExpectation, loadedAltRoutesExp: XCTestExpectation) {
                self.routeDeviationCallbackExp = routeDeviationCallbackExp
                self.loadedAltRoutesExp = loadedAltRoutesExp
            }

            func core(_ core: FerrostarCore, correctiveActionForDeviation deviationInMeters: Double, remainingWaypoints waypoints: [Waypoint]) -> CorrectiveAction {
                XCTAssertEqual(deviationInMeters, 42)
                self.routeDeviationCallbackExp.fulfill()
                return .getNewRoutes(waypoints: waypoints)
            }

            func core(_ core: FerrostarCore, loadedAlternateRoutes routes: [Route]) {
                XCTAssert(core.state?.isCalculatingNewRoute == true)  // We are still calculating until this method completes
                XCTAssert(!routes.isEmpty)
                self.loadedAltRoutesExp.fulfill()
            }
        }

        let delegate = CoreDelegate(routeDeviationCallbackExp: routeDeviationCallbackExp, loadedAltRoutesExp: loadedAltRoutesExp)
        core.delegate = delegate

        let routes = try await core.getRoutes(initialLocation: CLLocation(latitude: 60.5347155, longitude: -149.543469), waypoints: [Waypoint(coordinate: GeographicCoordinate(lat: 60.5349908, lng: -149.5485806), kind: .break)])

        locationProvider.lastLocation = CLLocation(latitude: 0, longitude: 0)
        let config = NavigationControllerConfig(stepAdvance: .relativeLineStringDistance(minimumHorizontalAccuracy: 16, automaticAdvanceDistance: 16), routeDeviationTracking: .custom(detector: { userLocation, route, step in
            // Pretend that the user is always off route
            .offRoute(deviationFromRouteLine: 42)
        }))

        try core.startNavigation(route: routes.first!, config: config)

        await fulfillment(of: [routeDeviationCallbackExp], timeout: 1.0)
        await fulfillment(of: [loadedAltRoutesExp], timeout: 1.0)

        XCTAssert(core.state?.isCalculatingNewRoute == false)
    }

    // TODO: Various location services failure modes (need special mocks to simulate these)

    // TODO: Test that state changes are picked up by the core when the user's location changes
}
