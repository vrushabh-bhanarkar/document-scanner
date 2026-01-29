# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep PDF related classes
-keep class com.syncfusion.** { *; }
-keep class com.syncfusion.flutter.** { *; }

# Keep image processing related classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Hive related classes
-keep class * extends io.objectbox.annotation.Entity { *; }
-keep class * extends io.objectbox.annotation.Id { *; }
-keep class * extends io.objectbox.annotation.Index { *; }
-keep class * extends io.objectbox.annotation.Unique { *; }
-keep class * extends io.objectbox.annotation.ToOne { *; }
-keep class * extends io.objectbox.annotation.ToMany { *; }

# Keep model classes
-keep class com.example.docscanner.models.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
} 

# Flutter Play Core SplitCompat
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ML Kit Text Recognition (all languages)
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.common.** { *; }
-dontwarn com.google.mlkit.vision.common.**

# Play Core Tasks
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.tasks.** 