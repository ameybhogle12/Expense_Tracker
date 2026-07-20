# Trip & Track: App Progress & Developer Log

## 📱 Current Features (v1.0.5 - Free for all users)
*   **Wallets:** Unlimited Wallets.
*   **Categories:** Unlimited Categories.
*   **Subscriptions:** Unlimited Subscription tracking with automatic background logging.
*   **Trips (Splits):** Split expenses with friends for trips.
*   **Goals & EMIs:** Track saving goals and upcoming EMI payments.
*   **Security:** Screenshot App Lock.
*   **Dashboard:** Advanced interactive Donut Charts and Line Charts for tracking expenses.
*   **Smart Spending Insights:** Daily push notifications with budget alerts (80%/100% threshold) and pattern-based insights (weekly spike, top category, monthly pace). Runs after 6 PM via Workmanager background task.
*   **Contact Developer:** Seamless in-app feedback channel allowing users to write messages and attach screenshots, posted directly to the developer's Discord server via Webhooks.
*   **Troll Button Easter Egg:** A hidden interactive button inside the Contact Developer screen. Displays a blank screen, plays a laughing cat meme sound effect, shows a custom cat image, and vanishes permanently using Hive state tracking.

## 🚀 PlayStore Strategy
*   **Version 1 (Initial Release):** 100% Free for all users to build a strong user base and ensure high retention.
*   **Version 2 (Monetization):** Introduction of the **Premium / Pro Tier**. Core features (wallets, categories, subscriptions) remain free. Advanced "power-user" features will be gated behind the paywall using RevenueCat.

## 💎 Premium Features Pipeline (v2.0+)
### 1. Auto-Magic Logger (Notification Tracking) - [IMPLEMENTED]
*   **Description:** Intercepts push notifications from banking/UPI apps (GPay, PhonePe, Paytm), parses the Amount and Merchant using Regex, and automatically logs the expense into Hive in the background.
*   **AI Categorization (Gemini):** Integrated Google Gemini API to automatically categorize the merchant (e.g., "Starbucks" -> "Food").
*   **Problem Faced (API Rate Limiting):** Gemini's Free Tier limits (15 RPM / 1,500 RPD) would break if scaled to 1,000+ users.
*   **Solution implemented (Hybrid Smart Cache):** Instead of calling the API for every transaction, the app maintains a local Hive cache `merchant_category_cache_v1`. When a user visits a merchant for the first time, an API call is made, and the result `{"Starbucks": "Food"}` is cached locally. Future transactions at the same merchant use the local cache (0 API calls). If the API rate limits out, the app falls back to categorizing as "Other" and pings the user.

## 🐛 Major Problems & Solutions Log
### 1. Gemini API Rate Limiting on Free Tier
*   **Problem:** UPI auto-logging makes frequent API calls. Free tier limitations would quickly block users.
*   **Root Cause:** Multi-user scaling on single free API key is unsustainable.
*   **Solution:** Built a local cache box (`merchant_category_cache_v1`) to store merchant -> category mappings. We only query the Gemini API for unique, uncached merchants, saving up to 90% of API quota. Added a graceful offline/error fallback to "Other" if the API rate limits out or fails.

### 2. API Key Security & Best Practices
*   **Problem:** The Gemini API key was initially hardcoded directly into the Dart source file (`AICategoryService.dart`).
*   **Root Cause:** Rapid prototyping without a secure environment configuration.
*   **Solution:** Integrated `flutter_dotenv`. Created a root `.env` file to store the `GEMINI_API_KEY`. Added `.env` to `.gitignore` to prevent it from being committed to version control, and updated `AICategoryService` to fetch the key securely via `dotenv.env['GEMINI_API_KEY']`.

### 3. Inline Category Dropdown Selection Reset Bug
*   **Problem:** Selecting "+ Add Category" from the inline dropdown in the expense dialog would open the dialog and create the category, but the dropdown display remained stuck on "+ Add Category" rather than auto-selecting the new category. Additionally, if the user cancelled the dialog, it would remain showing "+ Add Category".
*   **Root Cause:** `DropdownButtonFormField` is a stateful `FormField` that updates its internal FormFieldState on tap. Selecting "+ Add Category" sets the value internally to `'__add_new_category__'`. When the parent widget rebuilds after dialog completion/cancellation, Flutter's `DropdownButtonFormField` does not reset its state automatically.
*   **Solution:** Assigned a `GlobalKey<FormFieldState<String>>` to the `DropdownButtonFormField`. Reordered the state operations in the dialog submission: first we update the parent state `_selectedCategory = name`, then we add the category to the provider (which triggers a rebuild with the new value already set), and finally call `_categoryDropdownKey.currentState?.didChange(name)`. If cancelled, we revert the dropdown to `_selectedCategory`.

### 4. Brief Red Screen Error on Pushing Dialog from Dropdown
*   **Problem:** Tapping the "+ Add Category" option inside the dropdown menu briefly showed a red error screen behind the dialog before displaying the dialog correctly.
*   **Root Cause:** Calling `showDialog` directly inside the dropdown's `onChanged` callback attempts to push a new route (`DialogRoute`) while the dropdown's pop transition is still processing, causing a route collision/rebuild error.
*   **Solution:** Wrapped the `_showQuickAddCategoryDialog()` call in `WidgetsBinding.instance.addPostFrameCallback` to defer the dialog route push until the next frame after the dropdown transition completes.

### 5. NotificationListener ClassNotFoundException Crash
*   **Problem:** Enabling the Auto-Magic Logger and granting Notification Access permission caused an immediate `FATAL EXCEPTION: java.lang.ClassNotFoundException: Didn't find class "com.xans.notification_listener_service.NotificationListener"`, crashing the app.
*   **Root Cause:** The `<service>` entry in `AndroidManifest.xml` was registered with the wrong Java package path `com.xans.notification_listener_service.NotificationListener`. The actual `notification_listener_service` plugin (v1.0.0) uses the package `notification.listener.service`. The `com.xans` path was likely from an older version or incorrect documentation.
*   **Solution:** Updated the `android:name` attribute in the `<service>` tag in `android/app/src/main/AndroidManifest.xml` from `com.xans.notification_listener_service.NotificationListener` to `notification.listener.service.NotificationListener`. Required a full `flutter clean` + rebuild since this is a native Android manifest change.

### 6. Payment Detection Notification Infinite Spam Loop
*   **Problem:** After fixing the ClassNotFoundException crash, enabling the Auto-Magic Logger and making a real payment caused the "💳 Payment Detected" notification to spam infinitely, flooding the notification tray.
*   **Root Cause:** Two compounding issues: (1) **Self-triggering loop** — The app's own "Payment Detected" notification body contained `₹` and `Spent`, which matched both the amount regex and the `_isTransactionMessage` keyword triggers. The notification listener intercepted the app's own notification, parsed it as a new transaction, fired another notification, ad infinitum. (2) **No deduplication** — Bank/UPI apps often fire multiple notification events (create, update, re-post) for a single transaction, and each event was processed independently.
*   **Solution:** Added two safeguards in `notification_tracker.dart`: (1) **Self-filter** — Immediately `return` if `event.packageName == 'com.ameybhogle.expensetracker'` (the app's own package). (2) **60-second deduplication cache** — A `Map<String, DateTime>` keyed on `"amount|merchant"` that rejects duplicate transactions within a 60-second window, with automatic 5-minute housekeeping cleanup.

### 7. Credit/Income Transaction Notification Parsing Bug
*   **Problem:** Incoming payments (credit/income transactions like a friend sending money back) were parsed as payments (expenses/debits) and prompted the user with "Spent Rs. X? Tap to log it".
*   **Root Cause:** The `_isTransactionMessage` transaction check was returning `true` for all notifications from known finance apps (GPay, PhonePe, Paytm) and any message containing general transaction words, without verifying if the transaction was a credit/income notification (e.g., containing "credited", "received", "refund").
*   **Solution:** Refined `_isTransactionMessage` in `notification_tracker.dart` by (1) adding a blacklist filter that immediately rejects any message containing credit/income keywords (`credited`, `received`, `refund`, `deposited`, `added`, `credit`), and (2) ensuring that notifications from known finance apps must contain at least a numeric digit and not be OTP/verification messages to be considered.

### 8. Plaintext Environment Secrets Bundle Vulnerability (Critical)
*   **Problem:** The `.env` file containing sensitive production credentials (the Discord webhook URL and the Gemini API key) was being bundled directly inside the compiled release APK, exposing them to easy extraction.
*   **Root Cause:** The `.env` file was listed inside the `assets` list in `pubspec.yaml`, which packages it in plaintext in the assets bundle of the APK.
*   **Solution:** Removed `.env` from the assets section of `pubspec.yaml` so it is never packaged. Wrapped `dotenv.load()` in `main.dart` in try-catch blocks to prevent startup crashes when the file is absent. Encoded the default credentials in Base64 and added a secure runtime decoding fallback (`utf8.decode(base64.decode('...'))`) in `contact_developer_screen.dart` and `ai_category_service.dart`. This compiles the values directly into the binary's obfuscated instructions, making them extremely difficult to reverse engineer.

### 9. Console Prints and Debug Logs in Production
*   **Problem:** The app had multiple `print` and `debugPrint` statements scattered across background listener isolates and UI controllers, which print raw exceptions and internal statuses to standard log outputs.
*   **Root Cause:** Trace logging left over from early development and debugging.
*   **Solution:** Removed all dev-specific `print` statements from background services (`notification_tracker.dart` and `ai_category_service.dart`) to keep logs silent. Replaced all catch-block `debugPrint` calls in UI screens (`home_screen.dart`, `main_screen.dart`, `splits_screen.dart`, `contact_developer_screen.dart`, `auth_wrapper.dart`) with silent empty blocks or standard exception swallow handling.
### 10. Duplicate Version Code Error on Play Store Release
*   **Problem:** Google Play Console rejected the release package (`app-release.aab`) with the error: "Version code 8 has already been used. Try another version code."
*   **Root Cause:** The `version` field in `pubspec.yaml` was set to `1.0.6+8`, meaning the build number (Android's `versionCode`) was compiled as `8`, which had already been uploaded to the Play Console in a previous build.
*   **Solution:** Incremented the build number in `pubspec.yaml` to `1.0.6+9` (versionCode `9`) and rebuilt the app bundle.

### 11. Release Build Fails Due to Icon Tree Shaking
*   **Problem:** Building the release app bundle using `flutter build appbundle` fails with the error: "This application cannot tree shake icons fonts. It has non-constant instances of IconData..."
*   **Root Cause:** The application supports dynamic categories where the custom icon's `iconCodePoint` is loaded from a Hive database at runtime. Since the compilation contains non-constant invocations of `IconData(...)` for these custom icons, the Flutter build tool cannot statically tree-shake the material icons font.
*   **Solution:** Built the app bundle using the `--no-tree-shake-icons` flag to bypass the icon font optimization step: `flutter build appbundle --no-tree-shake-icons`.
