# Upcoming Features — Expense Tracker

## Priority Tasks (Next Session)

### 1. 🎮 Multiplayer / Sync Mode
- Allow sharing a trip with friends so multiple people can add expenses in real-time
- Options to explore:
  - **Firebase Realtime DB / Firestore** — Cloud sync, real-time listeners
  - **QR Code sharing** — One person hosts, others scan to join
  - **Export/Import JSON** — Offline sharing via WhatsApp/Telegram
- Consideration: Conflict resolution when two people add expenses simultaneously

### 2. ✨ Animations & Transitions
- Page transitions feel abrupt — add smooth slide/fade between screens
- Balance bars should animate when values change
- Settlement cards should stagger-animate in
- Expense list items should animate on add/remove
- FAB should have a satisfying press animation

### 3. 🤖 AI Integration & Smart Suggestions
- Explore options that DON'T require paid API keys:
  - **Ollama (local LLM)** — On-device inference (heavy, may not work on mobile)
  - **Google Gemini Nano** — On-device via ML Kit (limited availability)
  - **Rule-based "AI"** — Smart suggestions without actual LLM:
    - "You usually spend ₹X on food" patterns
    - Category auto-detection from description text
    - Budget warnings based on spending trends
    - Trip cost predictions based on past trips
  - **Gemini API Free Tier** — 15 requests/minute free (good for light usage)

---

## Parked Features (From LATER_UPDATES.md)
- SMS Inbox Polling for auto-logging transactions
- See `LATER_UPDATES.md` for full technical plan
