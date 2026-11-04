# Maps 3.3.1 compiles its Google location engine against optional Play Services.
# LocationEngineProvider checks the classpath and falls back to Android location
# when Play Services Location is absent. The SDK's rules cover location/common
# but omit these task callback types, which otherwise break R8 for such hosts.
# Keep this list narrow; do not suppress unrelated missing dependencies.
-dontwarn com.google.android.gms.tasks.OnFailureListener
-dontwarn com.google.android.gms.tasks.OnSuccessListener
-dontwarn com.google.android.gms.tasks.Task
