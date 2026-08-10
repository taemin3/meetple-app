import 'nearby_location.dart';
import 'nearby_location_provider_stub.dart'
    if (dart.library.io) 'nearby_location_provider_mobile.dart' as platform;

export 'nearby_location.dart';

NearbyLocationProvider createNearbyLocationProvider() {
  return platform.createNearbyLocationProvider();
}
