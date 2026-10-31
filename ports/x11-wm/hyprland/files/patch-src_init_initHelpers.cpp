--- src/init/initHelpers.cpp.orig
+++ src/init/initHelpers.cpp
@@ -1,4 +1,4 @@
-#if !defined(__OpenBSD__)
+#if defined(__linux__)
 #include <linux/capability.h>
 #include <sys/prctl.h>
 #endif
@@ -25,7 +25,9 @@
 // NixOS-specific fix to prevent all children from inheriting
 // CAP_SYS_NICE due to how the security wrapper works.
 void NInit::lowerAmbientCaps() {
+#if defined(__linux__)
     prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_LOWER, CAP_SYS_NICE, 0, 0);
+#endif
 }
 #endif
 
