// rice: privacy and appearance prefs for Thunderbird profiles.
// bin/rice-browser-setup writes this between "rice" markers in each profile's user.js (the rest of
// the file is yours). Applied at every start; change a value here, not in the Config Editor.
// Names: Thunderbird mail/app/profile/all-thunderbird.js, mailnews/mailnews.js (comm-central main
// 2026-10-30); toolkit.* as in Firefox (config/browsers/user.js). Checked by
// tests/browsers/check_thunderbird.py. Docs: docs/knowledge-base/browsers.md#thunderbird.

// ---- Telemetry and data reporting: off ----
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);

// ---- Privacy in mail ----
user_pref("mailnews.start_page.enabled", false);                 // no remote start page
user_pref("mailnews.message_display.disable_remote_image", true); // default; stated so it stays
user_pref("mail.shell.checkDefaultClient", false);

// ---- Appearance: built-in Dark theme + palette userChrome.css ----
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("extensions.activeThemeID", "thunderbird-compact-dark@mozilla.org");
