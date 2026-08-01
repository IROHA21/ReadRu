# Google ML Kit (on-device translation) - GoogleMlKitTranslationPlugin,
# GenericModelManager, and the underlying Play Services RemoteModelManager
# are only ever referenced via Flutter's generated plugin registrant and
# reflection, never directly from app code. Without these rules R8 strips
# them as unused in release builds (confirmed via
# build/app/outputs/mapping/release/usage.txt), which registers no handler
# for the google_mlkit_on_device_translator method channel and throws
# MissingPluginException at runtime - in release only, since R8 doesn't
# run for debug builds.
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_translation.** { *; }
-dontwarn com.google.mlkit.**
