/// Various re-exported models.
///
/// This wrapper approach is unfortunaetly necessary beacuse Swift packages cannot yet
/// re-export inner modules. The types used in signatures have the information available, and values
/// returned from functions can be inspected, but the type name cannot be explicitly used in variable or
/// function signatures. So to work around the issue, we export a wrapper type that *can* be
/// referenced in other packages (like the UI) which need to hang on to the route without getting the whole
/// FFI.

import Foundation
import CoreLocation
import UniFFI

/// A wrapper around the FFI `Route`.
public struct Route {
    let inner: UniFFI.Route

    var geometry: [CLLocationCoordinate2D] {
        inner.geometry.map { point in
            CLLocationCoordinate2D(latitude: point.lat, longitude: point.lng)
        }
    }
}

/// A wrapper around the FFI `NavigationStateUpdate`.
public struct NavigationStateUpdate {
    let inner: UniFFI.NavigationStateUpdate
}
