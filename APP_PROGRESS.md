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

