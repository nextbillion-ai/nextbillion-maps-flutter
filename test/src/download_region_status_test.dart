import 'package:flutter/services.dart';
import 'package:nb_maps_flutter/nb_maps_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('DownloadRegionStatus', () {
    test('Success should be an instance of DownloadRegionStatus', () {
      // Arrange
      final DownloadRegionStatus status = Success();

      // Assert
      expect(status, isA<DownloadRegionStatus>());
    });

    test('InProgress should be an instance of DownloadRegionStatus', () {
      // Arrange
      const double progress = 0.5;
      final DownloadRegionStatus status = InProgress(progress);

      // Assert
      expect(status, isA<DownloadRegionStatus>());
    });

    test('InProgress should have correct progress value', () {
      // Arrange
      const double progress = 0.5;
      final InProgress status = InProgress(progress);

      // Assert
      expect(status.progress, equals(progress));
    });

    test('InProgress should have correct toString representation', () {
      // Arrange
      const double progress = 0.5;
      final DownloadRegionStatus status = InProgress(progress);

      // Assert
      expect(
        status.toString(),
        "Instance of 'DownloadRegionStatus.InProgress', progress = $progress",
      );
    });

    test('Error should be an instance of DownloadRegionStatus', () {
      // Arrange
      final PlatformException cause =
          PlatformException(code: 'error_code', message: 'error_message');
      final DownloadRegionStatus status = Error(cause);

      // Assert
      expect(status, isA<DownloadRegionStatus>());
    });

    test('Error should have correct cause value', () {
      // Arrange
      final PlatformException cause =
          PlatformException(code: 'error_code', message: 'error_message');
      final Error status = Error(cause);

      // Assert
      expect(status.cause, equals(cause));
    });

    test('Error should have correct toString representation', () {
      // Arrange
      final PlatformException cause =
          PlatformException(code: 'error_code', message: 'error_message');
      final DownloadRegionStatus status = Error(cause);

      // Assert
      expect(
        status.toString(),
        "Instance of 'DownloadRegionStatus.Error', cause = $cause",
      );
    });
  });
}
