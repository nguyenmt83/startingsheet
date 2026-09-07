import zipfile
import xml.etree.ElementTree as ET
import json
import os
import re

xlsx_path = r"d:\PHOENIX\STARTING SHEET - PHOENIX CV Golf & Resort.xlsx"
output_json_path = r"d:\PHOENIX\Xây dựng Ứng dụng Quản lý Sân Golf - Google Gemini_files\parsed_sheet.json"

def get_column_letter(cell_ref):
    match = re.match(r"([A-Z]+)([0-9]+)", cell_ref)
    if match:
        return match.group(1), int(match.group(2))
    return cell_ref, 0

def parse_xlsx(file_path):
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

        sheet_files = [name for name in z.namelist() if name.startswith('xl/worksheets/sheet') and name.endswith('.xml')]
        print(f"Found sheet files: {sheet_files}")

        all_sheets_data = {}
        ns = {'main': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

        for s_file in sheet_files:
            with z.open(s_file) as f:
                tree = ET.parse(f)
                root = tree.getroot()
                
                rows_data = []
                for row in root.findall('.//main:row', ns):
                    row_idx = int(row.attrib.get('r', 0))
                    row_dict = {}
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
                                
                        col_letter, r_num = get_column_letter(ref)
                        row_dict[col_letter] = val
                    
                    if row_dict:
                        rows_data.append({"row": row_idx, "cells": row_dict})
                
                all_sheets_data[s_file] = rows_data

        return all_sheets_data

try:
    data = parse_xlsx(xlsx_path)
    with open(output_json_path, 'w', encoding='utf-8') as out:
        json.dump(data, out, ensure_ascii=False, indent=2)
    print(f"SUCCESS: Saved parsed data to {output_json_path}")
except Exception as e:
    print(f"ERROR: {e}")
