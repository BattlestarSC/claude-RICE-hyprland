// rice: privacy and appearance prefs for Firefox profiles.
// bin/rice-browser-setup writes this between "rice" markers in each profile's user.js;
// everything outside the markers is yours and is kept. user.js is applied at every start,
// so changing one of these in about:config lasts only until the next start: change it here.
// Pref names checked against arkenfox user.js v144 (2026-09-09) and Firefox's firefox.js / all.js /
// StaticPrefList.yaml (main, 2026-10-30). Sources: docs/knowledge-base/browsers.md.

// ---- Telemetry, studies, crash reports: off ----
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
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// ---- Background connections Mozilla makes on its own ----
user_pref("captivedetect.canonicalURL", "");
user_pref("network.captive-portal-service.enabled", false);   // hotel/airport Wi-Fi login pages won't pop up
user_pref("network.connectivity-service.enabled", false);

// ---- Recommendations, sponsored content, AI features ----
user_pref("browser.discovery.enabled", false);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false);

// ---- Leaks: speculative connections, prefetching, WebRTC local IPs ----
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.places.speculativeConnect.enabled", false);
user_pref("media.peerconnection.ice.default_address_only", true);
user_pref("privacy.globalprivacycontrol.enabled", true);
// Search suggestions send every keystroke in the address bar to the search engine.
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);

// ---- Appearance: dark UI and content, palette userChrome.css ----
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("layout.css.prefers-color-scheme.content-override", 0);   // 0 dark, 1 light, 2 follow the browser
