import zipfile
import xml.etree.ElementTree as ET
import json
import os
import re
import subprocess
from datetime import datetime

# Paths
WORKSPACE_DIR = os.path.dirname(os.path.abspath(__file__))
PARENT_DIR = os.path.dirname(WORKSPACE_DIR)
INDEX_HTML = os.path.join(WORKSPACE_DIR, "index.html")
OMS_HTML = os.path.join(WORKSPACE_DIR, "phoenix_smart_starting_oms.html")

# Possible Excel file locations
EXCEL_CANDIDATES = [
    os.path.join(PARENT_DIR, "STARTING SHEET - PHOENIX CV Golf & Resort.xlsx"),
    os.path.join(WORKSPACE_DIR, "STARTING SHEET - PHOENIX CV Golf & Resort.xlsx"),
    os.path.join(PARENT_DIR, "starting_sheet.xlsx"),
    os.path.join(WORKSPACE_DIR, "starting_sheet.xlsx")
]

excel_path = None
for p in EXCEL_CANDIDATES:
    if os.path.exists(p):
        excel_path = p
        break

if not excel_path:
    # Look for any .xlsx starting with STARTING
    for root, dirs, files in os.walk(PARENT_DIR):
        for f in files:
            if f.lower().endswith(".xlsx") and "starting" in f.lower():
                excel_path = os.path.join(root, f)
                break
        if excel_path:
            break

print("=" * 70)
print("   PHOENIX CV GOLF & RESORT - TỰ ĐỘNG CẬP NHẬT DỮ LIỆU TỪ EXCEL")
print("=" * 70)

if not excel_path:
    print(f"[LỖI] Không tìm thấy file Excel 'STARTING SHEET - PHOENIX CV Golf & Resort.xlsx'!")
    print(f"Vui lòng đảm bảo file đã được tải vào thư mục d:\\PHOENIX")
    input("Bấm Enter để thoát...")
    exit(1)

print(f"[*] Tìm thấy file Excel: {excel_path}")

def get_col_letter_and_row(cell_ref):
    m = re.match(r"([A-Z]+)([0-9]+)", cell_ref)
    if m:
        return m.group(1), int(m.group(2))
    return cell_ref, 0

def parse_xlsx_to_grid(file_path):
    with zipfile.ZipFile(file_path, 'r') as z:
        shared_strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            with z.open('xl/sharedStrings.xml') as f:
                tree = ET.parse(f)
                root = tree.getroot()
                ns = {'main': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
                for si in root.findall('.//main:si', ns):
                    texts = [t.text for t in si.findall('.//main:t', ns) if t.text]
                    shared_strings.append("".join(texts))

        # Find sheets
        sheet_files = [s for s in z.namelist() if s.startswith('xl/worksheets/sheet') and s.endswith('.xml')]
        if not sheet_files:
            return []

        # Read sheet 1 (or the largest sheet)
        main_sheet = sheet_files[0]
        ns = {'main': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
        
        with z.open(main_sheet) as f:
            tree = ET.parse(f)
            root = tree.getroot()
            
            rows_grid = []
            for row in root.findall('.//main:row', ns):
                r_idx = int(row.attrib.get('r', 0))
                cell_dict = {}
                for c in row.findall('.//main:c', ns):
                    ref = c.attrib.get('r', '')
                    t = c.attrib.get('t', '')
                    v_el = c.find('main:v', ns)
                    val = v_el.text if v_el is not None else ""

                    if t == 's' and val.isdigit():
                        idx = int(val)
                        val = shared_strings[idx] if idx < len(shared_strings) else val
                    elif t == 'inlineStr':
                        is_t = c.find('.//main:t', ns)
                        if is_t is not None and is_t.text:
                            val = is_t.text

                    col_letter, _ = get_col_letter_and_row(ref)
                    cell_dict[col_letter] = str(val).strip()
                
                if cell_dict:
                    rows_grid.append((r_idx, cell_dict))
            
            return rows_grid

print("[*] Đang đọc nội dung các ô trong bảng tính...")
rows_grid = parse_xlsx_to_grid(excel_path)
print(f"[*] Đã đọc được {len(rows_grid)} hàng dữ liệu.")

# Analyze columns and find header row
header_row_idx = None
col_mapping = {}

# Search for header row
for r_idx, cells in rows_grid[:25]:
    cell_values = [v.lower() for v in cells.values()]
    joined = " ".join(cell_values)
    if ("tee" in joined or "hố" in joined or "giờ" in joined or "time" in joined) and \
       ("tên" in joined or "name" in joined or "golfer" in joined or "khách" in joined or "locker" in joined or "caddie" in joined):
        header_row_idx = r_idx
        for col, val in cells.items():
            v_low = val.lower()
            if "stt" in v_low or "flight" in v_low or "no" in v_low:
                col_mapping["flightNo"] = col
            elif "sân" in v_low or "course" in v_low:
                col_mapping["course"] = col
            elif "tee" in v_low and ("box" in v_low or "hố" in v_low or "xuất" in v_low):
                col_mapping["teeBox"] = col
            elif "giờ" in v_low or "time" in v_low or "tee" in v_low:
                if "teeTime" not in col_mapping:
                    col_mapping["teeTime"] = col
                elif "finish" in v_low or "xong" in v_low:
                    col_mapping["finishTime"] = col
            elif "tên" in v_low or "name" in v_low or "golfer" in v_low or "khách" in v_low:
                col_mapping["name"] = col
            elif "locker" in v_low or "tủ" in v_low:
                col_mapping["locker"] = col
            elif "caddie" in v_low or "cd" in v_low:
                col_mapping["caddie"] = col
            elif "cart" in v_low or "xe" in v_low:
                col_mapping["cart"] = col
            elif "phí" in v_low or "fee" in v_low or "tiền" in v_low:
                col_mapping["fee"] = col
            elif "hố" in v_low or "hole" in v_low or "vòng" in v_low:
                col_mapping["holes"] = col
            elif "ghi chú" in v_low or "note" in v_low or "chuyển" in v_low:
                col_mapping["note"] = col
        break

print(f"[*] Hàng tiêu đề: {header_row_idx}")
print(f"[*] Bản đồ cột nhận diện: {col_mapping}")

# Fallback column mapping if not detected from text
if not col_mapping.get("name"):
    col_mapping = {
        "flightNo": "A",
        "course": "B",
        "teeBox": "C",
        "teeTime": "D",
        "name": "E",
        "locker": "F",
        "caddie": "G",
        "cart": "H",
        "holes": "I",
        "note": "J",
        "fee": "K"
    }
    header_row_idx = 1

# Extract flights
flights_list = []
current_flight = None
flight_counter = 1

for r_idx, cells in rows_grid:
    if header_row_idx and r_idx <= header_row_idx:
        continue

    # Read cell values by mapping or by position
    name = cells.get(col_mapping.get("name", "E"), "").strip()
    if not name:
        # Check adjacent columns for a name
        for k in ["D", "E", "F", "C", "B"]:
            val = cells.get(k, "").strip()
            if len(val) > 2 and not val.isdigit() and not ":" in val:
                name = val
                break

    if not name:
        continue

    flight_str = cells.get(col_mapping.get("flightNo", "A"), "").strip()
    course_str = cells.get(col_mapping.get("course", "B"), "").strip()
    teebox_str = cells.get(col_mapping.get("teeBox", "C"), "").strip()
    teetime_str = cells.get(col_mapping.get("teeTime", "D"), "").strip()
    locker_str = cells.get(col_mapping.get("locker", "F"), "").strip()
    caddie_str = cells.get(col_mapping.get("caddie", "G"), "").strip()
    cart_str = cells.get(col_mapping.get("cart", "H"), "").strip()
    holes_str = cells.get(col_mapping.get("holes", "I"), "").strip()
    note_str = cells.get(col_mapping.get("note", "J"), "").strip()
    fee_str = cells.get(col_mapping.get("fee", "K"), "").strip()

    # Determine fee
    fee_val = 140
    try:
        clean_fee = re.sub(r"[^\d.]", "", fee_str)
        if clean_fee:
            fee_num = float(clean_fee)
            fee_val = fee_num if fee_num < 1000 else fee_num / 1000
    except:
        fee_val = 140

    player_obj = {
        "name": name,
        "locker": locker_str if locker_str else "N/A",
        "gender": "Female" if ("mrs" in name.lower() or "ms" in name.lower() or "bà" in name.lower() or "chị" in name.lower()) else "Male",
        "age": "45 - 55",
        "booking": "BOOKING" if fee_val >= 190 else "NON BOOKING",
        "caddie": caddie_str if caddie_str else "Chưa gán",
        "cart": cart_str if cart_str else "Đi bộ",
        "fee": fee_val
    }

    # Decide if this starts a new flight or continues previous flight
    is_new_flight = False
    if flight_str and (flight_str.isdigit() or "#" in flight_str):
        is_new_flight = True
    elif teetime_str and ":" in teetime_str:
        is_new_flight = True
    elif current_flight is None or len(current_flight["players"]) >= 4:
        is_new_flight = True

    if is_new_flight:
        course = "CHAMPION"
        c_upper = (course_str + " " + teebox_str).upper()
        if "D" in c_upper or "DRAGON" in c_upper:
            course = "DRAGON"
        elif "P" in c_upper or "PHOENIX" in c_upper:
            course = "PHOENIX"

        tee_box = teebox_str.upper() if teebox_str else ("C1" if course == "CHAMPION" else "D1" if course == "DRAGON" else "P1")
        if not any(tee_box.startswith(prefix) for prefix in ["C", "D", "P"]):
            tee_box = ("C" if course == "CHAMPION" else "D" if course == "DRAGON" else "P") + tee_box

        tee_time = teetime_str if (teetime_str and ":" in teetime_str) else "06:30"
        holes = "18 HOLES"
        if "27" in holes_str or "27" in note_str:
            holes = "27 HOLES"
        elif "36" in holes_str or "36" in note_str:
            holes = "36 HOLES"

        current_flight = {
            "id": int(datetime.now().timestamp() * 1000) + len(flights_list),
            "flightNo": len(flights_list) + 1,
            "course": course,
            "teeBox": tee_box,
            "teeTime": tee_time,
            "finishTime": "",
            "status": "WAITING",
            "holes": holes,
            "note": note_str if note_str else "Bình thường",
            "players": [player_obj]
        }
        flights_list.append(current_flight)
    else:
        current_flight["players"].append(player_obj)

print(f"[THÀNH CÔNG] Đã trích xuất thành công {len(flights_list)} Flights ({sum(len(f['players']) for f in flights_list)} Golfers)!")

# Update index.html and phoenix_smart_starting_oms.html
json_str = json.dumps(flights_list, ensure_ascii=False, indent=2)

def update_html_seed_data(filepath, new_json_str):
    if not os.path.exists(filepath):
        return False
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to find initialRawData = [ ... ];
    pattern = r'(const\s+initialRawData\s*=\s*)\[[\s\S]*?\];'
    replacement = r'\1' + new_json_str + ';'

    if re.search(pattern, content):
        new_content = re.sub(pattern, replacement, content, count=1)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

up1 = update_html_seed_data(INDEX_HTML, json_str)
up2 = update_html_seed_data(OMS_HTML, json_str)

if up1 and up2:
    print("[*] Đã cập nhật dữ liệu mới vào index.html và phoenix_smart_starting_oms.html!")
else:
    print("[CẢNH BÁO] Không thể tự động thay thế biến initialRawData trong HTML.")

# Git Auto Commit & Push
print("[*] Đang tự động đẩy lên GitHub...")
try:
    subprocess.run(["git", "add", "."], cwd=WORKSPACE_DIR, check=True)
    now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    subprocess.run(["git", "commit", "-m", f"feat: Update live starting sheet data from Google Sheet [{now_str}]"], cwd=WORKSPACE_DIR, check=True)
    push_res = subprocess.run(["git", "push", "origin", "main"], cwd=WORKSPACE_DIR)
    if push_res.returncode == 0:
        print("\n" + "=" * 70)
        print("   ✅ ĐÃ ĐỒNG BỘ LÊN GITHUB THÀNH CÔNG!")
        print("   Bây giờ bạn chỉ cần mở link online cũ và bấm F5 (hoặc vuốt tải lại trang)")
        print("   là sẽ thấy toàn bộ danh sách khách mới nhất!")
        print("=" * 70)
    else:
        print("\n⚠️ [CHƯA THỂ PUSH] Kiểm tra kết nối mạng hoặc quyền GitHub.")
except Exception as e:
    print(f"\n[GHI CHÚ] Git push: {e}")

print("\nHoàn tất. Bấm Enter để đóng...")
