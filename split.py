import os
import re

base_dir = r"c:/Users/IT/Downloads/acess-_track-main/acess-_track-main/lib/admin"
file_path = os.path.join(base_dir, "admin_screens.dart")

with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace private shared helpers to public
replacements = {
    r'\b_EmptyCard\b': 'AdminEmptyCard',
    r'\b_ErrorCard\b': 'AdminErrorCard',
    r'\b_StatsShimmer\b': 'AdminStatsShimmer',
    r'\b_SheetHandle\b': 'AdminSheetHandle',
    r'\b_DetailCard\b': 'AdminDetailCard',
    r'\b_DetailRow\b': 'AdminDetailRow',
    r'\b_Field\b': 'AdminFormField',
    r'\b_Dropdown\b': 'AdminDropdown',
}

new_text = text
for k, v in replacements.items():
    new_text = re.sub(k, v, new_text)

lines = new_text.splitlines(True)

# Extract sections
header_lines = lines[:10]
imports_str = "".join(header_lines) + "import 'admin_shared.dart';\n"

# Helper to write files safely
def extract_section(start_str, end_str=None, limit_end=None):
    start_idx = 0
    for i, l in enumerate(lines):
        if start_str in l:
            start_idx = i
            break
    end_idx = len(lines)
    if end_str:
        for i in range(start_idx+1, len(lines)):
            if end_str in l and i < limit_end:
                pass
        # Wait, simple search
    return start_idx

# We know the approximate structures from grep.
dashboard_s = next(i for i, l in enumerate(lines) if "class AdminDashboardScreen" in l)
tasks_s = next(i for i, l in enumerate(lines) if "class AdminTasksScreen" in l)
techs_s = next(i for i, l in enumerate(lines) if "class AdminTechniciansScreen" in l)
devices_s = next(i for i, l in enumerate(lines) if "class AdminDevicesScreen" in l)
inspect_s = next(i for i, l in enumerate(lines) if "class AdminInspectionsScreen" in l)
system_s = next(i for i, l in enumerate(lines) if "class SystemManagementScreen" in l)

# Extra sections for shared helpers
helpers_empty_s = next(i for i, l in enumerate(lines) if "class AdminEmptyCard" in l)
helpers_handle_s = next(i for i, l in enumerate(lines) if "class AdminSheetHandle" in l)

# Reorder splits because of interleaving helpers?
# helpers_empty_s is before AdminTasksScreen
# helpers_handle_s is after SystemManagementScreen
dashboard_chunk = lines[dashboard_s:helpers_empty_s]
shared_1 = lines[helpers_empty_s:tasks_s]
tasks_chunk = lines[tasks_s:techs_s]
techs_chunk = lines[techs_s:devices_s]
devices_chunk = lines[devices_s:inspect_s]
inspect_chunk = lines[inspect_s:system_s]
system_chunk = lines[system_s:helpers_handle_s]
shared_2 = lines[helpers_handle_s:]

with open(os.path.join(base_dir, 'admin_shared.dart'), 'w', encoding='utf-8') as f:
    f.write(imports_str)
    f.writelines(shared_1)
    f.writelines(shared_2)

with open(os.path.join(base_dir, 'admin_dashboard_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(imports_str)
    f.writelines(dashboard_chunk)
    
with open(os.path.join(base_dir, 'admin_tasks_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(imports_str)
    f.writelines(tasks_chunk)

with open(os.path.join(base_dir, 'admin_technicians_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(imports_str)
    f.writelines(techs_chunk)
    
with open(os.path.join(base_dir, 'admin_devices_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(imports_str)
    f.writelines(devices_chunk)
    
with open(os.path.join(base_dir, 'admin_inspections_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(imports_str)
    f.writelines(inspect_chunk)

with open(os.path.join(base_dir, 'admin_system_management_screen.dart'), 'w', encoding='utf-8') as f:
    f.write(imports_str)
    f.writelines(system_chunk)

# Replace admin_screens.dart with barrel
with open(file_path, 'w', encoding='utf-8') as f:
    f.write('''export 'admin_dashboard_screen.dart';
export 'admin_tasks_screen.dart';
export 'admin_technicians_screen.dart';
export 'admin_devices_screen.dart';
export 'admin_inspections_screen.dart';
export 'admin_system_management_screen.dart';
export 'admin_shared.dart';
''')

print('Split complete.')
