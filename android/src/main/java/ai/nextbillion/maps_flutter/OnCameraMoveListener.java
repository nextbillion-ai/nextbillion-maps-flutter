
package ai.nextbillion.maps_flutter;


import ai.nextbillion.maps.camera.CameraPosition;

/** @noinspection unused*/
interface OnCameraMoveListener {
  void onCameraMoveStarted(boolean isGesture);

  void onCameraMove(CameraPosition newPosition);

  void onCameraIdle();
}
