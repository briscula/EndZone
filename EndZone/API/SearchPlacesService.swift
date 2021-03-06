import Combine
import MapKit

protocol SearchPlacesService {
    func query(placeName: String) -> AnyPublisher<[Place], Error>
}

class MapKitSearchPlaces: SearchPlacesService {
    private var search: MKLocalSearch?

    func query(placeName: String) -> AnyPublisher<[Place], Error> {
        Future { promise in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = placeName

            if let search = self.search {
                search.cancel()
            }
            self.search = MKLocalSearch(request: request)
            self.search?.start { (response, error) in
                guard let response = response else {
                    if let error = error {
                        promise(.failure(error))
                    }
                    return
                }

                let mapItems = response.mapItems.filter({ $0.timeZone != nil }).map {
                    Place(name: $0.name ?? "", timeZone: $0.timeZone!, coordinate: $0.placemark.coordinate)
                }

                promise(.success(mapItems))
            }
        }
        .handleEvents(receiveCancel: {
            self.search?.cancel()
        })
            .eraseToAnyPublisher()
    }
}
