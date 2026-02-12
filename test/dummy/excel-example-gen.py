# This file is used to generate a huge (at least 1GB) excel file with random data for testing purposes.
# The generated file is saved as "huge_events.xlsx".

from openpyxl import Workbook
import random
import string
from datetime import datetime

wb = Workbook(write_only=True)
ws = wb.create_sheet("events")

headers = [
    "event_id", "user_id", "session_id", "event_type", "source",
    "country", "device", "ip_address", "created_at", "payload"
]
ws.append(headers)

def random_string(size):
    return "".join(random.choices(string.ascii_letters + string.digits, k=size))

ROWS = 500_000

for i in range(ROWS):
    ws.append([
        i,
        random.randint(1, 500_000),
        random_string(24),
        random.choice(["click", "view", "purchase", "login"]),
        random.choice(["web", "ios", "android"]),
        random.choice(["US", "AR", "UY", "BR", "ES"]),
        random.choice(["mobile", "desktop", "tablet"]),
        f"{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}",
        datetime.utcnow().isoformat(),
        random_string(4000)
    ])

wb.save("tmp/huge_events.xlsx")
