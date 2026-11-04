# WorkManager's Room-backed WorkDatabase_Impl is only referenced via
# reflection, so R8 strips it as unused, which crashes the app on launch
# with "Unable to get provider androidx.startup.InitializationProvider" /
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
# WorkManager is pulled in transitively by google_mobile_ads; this app does
# not use it directly.
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}

# flutter_local_notifications stores scheduled notifications as JSON with
# Gson (reflection on its own model classes and generic type tokens).
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
