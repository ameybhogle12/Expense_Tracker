1. At the start of the app I noticed that my friends/Testers messaged me about why the main balance is in negative and i had to tell them that they have to enter a initial balance from their bank.

2. There is not edit feature in most of the screens, Like in EMI, Goals, etc there are just add and delete. Also the testers were confused aboout delete, they didnt knew that swipe left means delete.

3. Also the chart page is useless, i have asked my power BI friends to work with me to make dashboards. and asked them what will a normal person would like to see in front of them visually. So that we still have to design before publication

4. Payment detection only reliably catches the big 4 UPI apps (GPay, PhonePe, Paytm, BHIM), because those are matched by package name and skip the keyword check entirely. Everything else falls back to `isTransactionMessage` in `CustomNotificationListener.kt`, which has two problems:
   - It looks for contiguous phrases like "paid to" / "sent to", but real messages read "Paid Rs.10 to Rahul" with the amount in the middle, so the match fails. Bank apps and smaller UPI apps will silently get missed.
   - The credit/income filter matches substrings, so "credit" hits inside "credited" (intended) but ALSO rejects a genuine expense like "paid Rs.500 via credit card" (not intended).
   Fix is to match on word boundaries and allow the amount to sit between the verb and "to". Same logic is duplicated in Dart in `notification_tracker.dart`, so both need updating together.