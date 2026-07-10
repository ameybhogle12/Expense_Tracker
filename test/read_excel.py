import pandas as pd
import os

try:
    file_path = "C:/Amey/Projects/Flutter Projects/Expense_Tracker/test/Expense Tracker Testing Sheet.xlsx"
    df = pd.read_excel(file_path, sheet_name="Bugs")
    
    # Save as CSV
    csv_path = "C:/Amey/Projects/Flutter Projects/Expense_Tracker/test/bugs_sheet.csv"
    df.to_csv(csv_path)
    print(f"Successfully saved to {csv_path}")
except Exception as e:
    print(f"Error: {e}")

