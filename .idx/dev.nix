{pkgs}: {
  channel = "stable-24.05";
  packages = [
    pkgs.jdk17,
    pkgs.unzip,
    pkgs.android-sdk
  ];
  env = {
    ANDROID_HOME = "${pkgs.android-sdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${pkgs.android-sdk}/share/android-sdk";
  };
}