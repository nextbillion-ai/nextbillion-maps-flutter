import 'provider_start_device_test.dart' as fixed_provider;

/// Current acceptance scope: choose one provider before map creation, then
/// change styles on that map. Use TEST_PROVIDER=tomtom/maptiler/orbis in separate
/// processes. Same-MapView cross-provider switching remains out of scope.
void main() => fixed_provider.main();
