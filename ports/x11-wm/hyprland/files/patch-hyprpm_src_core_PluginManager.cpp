--- hyprpm/src/core/PluginManager.cpp.orig
+++ hyprpm/src/core/PluginManager.cpp
@@ -416,9 +416,6 @@
 eHeadersErrors CPluginManager::headersValid() {
     const auto HLVER = getHyprlandVersion(false);
 
-    if (!std::filesystem::exists(std::format("{}/share/pkgconfig/hyprland.pc", DataState::getHeadersPath())))
-        return HEADERS_MISSING;
-
     // find headers commit
     const std::string& cmd     = std::format("PKG_CONFIG_PATH=\"{}\" pkgconf --cflags --keep-system-cflags hyprland", getPkgConfigPath());
     auto               headers = execAndGet(cmd);
