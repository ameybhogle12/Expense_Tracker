import os
import csv
import random
from datetime import datetime, timedelta

# Create directory if it doesn't exist
output_dir = r"C:\Amey\Projects\Flutter Projects\Expense_Tracker\test\powerbi_mock_data"
os.makedirs(output_dir, exist_ok=True)

# 1. Budgets Data
budgets = [
    {"category": "Food", "monthlyLimit": 10000.0},
    {"category": "Transport", "monthlyLimit": 4000.0},
    {"category": "Bills", "monthlyLimit": 18000.0},
    {"category": "Entertainment", "monthlyLimit": 5000.0},
    {"category": "Shopping", "monthlyLimit": 8000.0},
    {"category": "Health", "monthlyLimit": 3000.0},
    {"category": "Other", "monthlyLimit": 5000.0}
]

with open(os.path.join(output_dir, "budgets.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["category", "monthlyLimit"])
    writer.writeheader()
    writer.writerows(budgets)

# 2. Goals Data
goals = [
    {"id": "goal_1", "name": "New Laptop", "targetAmount": 60000.0, "savedAmount": 25000.0, "deadline": "2026-10-31"},
    {"id": "goal_2", "name": "Europe Trip", "targetAmount": 150000.0, "savedAmount": 45000.0, "deadline": "2027-06-30"},
    {"id": "goal_3", "name": "Emergency Fund", "targetAmount": 50000.0, "savedAmount": 30000.0, "deadline": "2026-12-31"}
]

with open(os.path.join(output_dir, "goals.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["id", "name", "targetAmount", "savedAmount", "deadline"])
    writer.writeheader()
    writer.writerows(goals)

# 3. Subscriptions Data
subscriptions = [
    {"id": "sub_1", "amount": 499.0, "category": "Entertainment", "note": "Netflix", "paymentDay": 5, "paymentMethod": "Main Bank"},
    {"id": "sub_2", "amount": 199.0, "category": "Entertainment", "note": "Spotify", "paymentDay": 15, "paymentMethod": "UPI Lite"},
    {"id": "sub_3", "amount": 1500.0, "category": "Health", "note": "Gym Membership", "paymentDay": 1, "paymentMethod": "Main Bank"}
]

with open(os.path.join(output_dir, "subscriptions.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["id", "amount", "category", "note", "paymentDay", "paymentMethod"])
    writer.writeheader()
    writer.writerows(subscriptions)

# 4. EMIs Data
emis = [
    {"id": "emi_1", "itemName": "iPhone 15", "totalAmount": 72000.0, "monthlyInstallment": 6000.0, "totalMonths": 12, "monthsPaid": 6, "paymentDay": 10, "paymentMethod": "Main Bank"},
    {"id": "emi_2", "itemName": "MacBook Air", "totalAmount": 96000.0, "monthlyInstallment": 8000.0, "totalMonths": 12, "monthsPaid": 3, "paymentDay": 15, "paymentMethod": "Main Bank"}
]

with open(os.path.join(output_dir, "emis.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["id", "itemName", "totalAmount", "monthlyInstallment", "totalMonths", "monthsPaid", "paymentDay", "paymentMethod"])
    writer.writeheader()
    writer.writerows(emis)

# 5. Transactions Data (Spanning April, May, June 2026)
transactions = []
tx_id_counter = 1

def add_tx(amount, category, date_obj, note, payment_method, is_income):
    global tx_id_counter
    transactions.append({
        "id": f"tx_{tx_id_counter}",
        "amount": amount,
        "category": category,
        "date": date_obj.strftime("%Y-%m-%d %H:%M:%S"),
        "note": note,
        "paymentMethod": payment_method,
        "isIncome": str(is_income).lower()
    })
    tx_id_counter += 1

start_date = datetime(2026, 4, 1)
end_date = datetime(2026, 6, 30)

current_date = start_date
while current_date <= end_date:
    year = current_date.year
    month = current_date.month
    day = current_date.day

    # --- INCOMES ---
    # Monthly Salary on 1st
    if day == 1:
        add_tx(55000.0, "Other", datetime(year, month, 1, 9, 0), "Monthly Salary", "Main Bank", True)
    # Freelance Income (occasional)
    if month == 4 and day == 18:
        add_tx(6000.0, "Other", datetime(year, month, day, 14, 30), "Freelance Web Design", "Main Bank", True)
    if month == 5 and day == 12:
        add_tx(8500.0, "Other", datetime(year, month, day, 16, 0), "Consulting gig", "Main Bank", True)
    if month == 6 and day == 25:
        add_tx(12000.0, "Other", datetime(year, month, day, 11, 15), "Freelance App Dev", "Main Bank", True)

    # --- FIXED EXPENSES (matching EMIs and Subs) ---
    # Rent on 3rd
    if day == 3:
        add_tx(12000.0, "Bills", datetime(year, month, day, 10, 0), "Rent Payment", "Main Bank", False)
    # Netflix on 5th
    if day == 5:
        add_tx(499.0, "Entertainment", datetime(year, month, day, 8, 0), "Netflix Subscription", "Main Bank", False)
    # Gym on 1st
    if day == 1:
        add_tx(1500.0, "Health", datetime(year, month, day, 7, 30), "Gym Membership", "Main Bank", False)
    # Phone EMI on 10th
    if day == 10:
        add_tx(6000.0, "Bills", datetime(year, month, day, 12, 0), "EMI - iPhone 15", "Main Bank", False)
    # MacBook EMI on 15th
    if day == 15:
        add_tx(8000.0, "Bills", datetime(year, month, day, 12, 0), "EMI - MacBook Air", "Main Bank", False)
    # Spotify on 15th
    if day == 15:
        add_tx(199.0, "Entertainment", datetime(year, month, day, 9, 15), "Spotify Premium", "UPI Lite", False)
    # Electricity Bill around 8th
    if day == 8:
        add_tx(2300.0 + random.randint(-200, 300), "Bills", datetime(year, month, day, 18, 0), "Electricity Bill", "Main Bank", False)
    # Phone / Internet Bill around 20th
    if day == 20:
        add_tx(799.0, "Bills", datetime(year, month, day, 10, 0), "Wifi & Mobile Bill", "UPI Lite", False)

    # --- VARIABLE EXPENSES (Food, Transport, Shopping, Health, Other) ---
    # Food (almost every 1-2 days)
    if random.choice([True, False, False]):
        amount = round(random.uniform(150, 650), 2)
        add_tx(amount, "Food", datetime(year, month, day, 13, 0), "Groceries" if random.choice([True, False]) else "Restaurant dine out", "UPI Lite" if amount < 400 else "Main Bank", False)
    if random.choice([True, False, False, False]):
        amount = round(random.uniform(50, 200), 2)
        add_tx(amount, "Food", datetime(year, month, day, 17, 30), "Snacks & Coffee", "UPI Lite", False)

    # Transport (2-3 times a week)
    if current_date.weekday() in [0, 2, 4]:  # Mon, Wed, Fri
        amount = round(random.uniform(80, 250), 2)
        add_tx(amount, "Transport", datetime(year, month, day, 18, 30), "Auto / Cab Ride", "UPI Lite", False)
    if random.choice([True, False, False, False, False]):
        amount = round(random.uniform(500, 1500), 2)
        add_tx(amount, "Transport", datetime(year, month, day, 11, 0), "Petrol refill", "Main Bank", False)

    # Shopping (occasional weekend trips)
    if current_date.weekday() in [5, 6]:  # Sat, Sun
        if random.choice([True] + [False]*8):
            amount = round(random.uniform(1500, 5000), 2)
            add_tx(amount, "Shopping", datetime(year, month, day, 16, 0), "Clothes shopping" if random.choice([True, False]) else "Electronics accessories", "Main Bank", False)

    # Entertainment (movies, outings on weekends)
    if current_date.weekday() in [5, 6]:  # Sat, Sun
        if random.choice([True] + [False]*5):
            amount = round(random.uniform(300, 1200), 2)
            add_tx(amount, "Entertainment", datetime(year, month, day, 21, 0), "Movie Tickets" if random.choice([True, False]) else "Weekend pub/dinner", "Main Bank", False)

    # Health (pharmacy or doctor, random)
    if random.choice([True] + [False]*20):
        amount = round(random.uniform(200, 1200), 2)
        add_tx(amount, "Health", datetime(year, month, day, 15, 0), "Medicines" if random.choice([True, False]) else "Doctor consultation fee", "UPI Lite", False)

    # Other miscellaneous expenses
    if random.choice([True] + [False]*15):
        amount = round(random.uniform(100, 800), 2)
        add_tx(amount, "Other", datetime(year, month, day, 12, 0), "Miscellaneous purchase", "UPI Lite", False)

    current_date += timedelta(days=1)

# Write Transactions
with open(os.path.join(output_dir, "transactions.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["id", "amount", "category", "date", "note", "paymentMethod", "isIncome"])
    writer.writeheader()
    writer.writerows(transactions)

print(f"Successfully generated 5 CSV tables inside {output_dir}")
