import os
import re

lib_dir = r"c:/Users/IT/Downloads/acess-_track-main/acess-_track-main/lib/admin"

def add_imports(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'package:access_track/admin/admin_screens.dart' not in content:
        content = content.replace("import 'package:access_track/core/app_theme.dart';", "import 'package:access_track/core/app_theme.dart';\nimport 'package:access_track/admin/admin_screens.dart';\nimport 'package:access_track/core/widgets/widgets.dart';")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for fn in os.listdir(lib_dir):
    if fn.endswith('.dart'):
        add_imports(os.path.join(lib_dir, fn))

# Now, we need to extract _AdminWelcomeHero and _AnalyticsCard from admin_inspections_screen.dart and move them to admin_dashboard_screen.dart

def move_classes():
    insp_path = os.path.join(lib_dir, "admin_inspections_screen.dart")
    dash_path = os.path.join(lib_dir, "admin_dashboard_screen.dart")
    
    with open(insp_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    start_hero = -1
    start_analytics = -1
    for i, l in enumerate(lines):
        if "class _AdminWelcomeHero" in l:
            start_hero = i
        if "class _AnalyticsCard" in l:
            start_analytics = i
            
    if start_hero != -1 and start_analytics != -1:
        # Assuming they go till the end of the file or until SystemScreen
        hero_and_analytics = lines[start_hero:]
        insp_lines = lines[:start_hero]
        
        with open(insp_path, 'w', encoding='utf-8') as f:
            f.writelines(insp_lines)
            
        with open(dash_path, 'a', encoding='utf-8') as f:
            f.write('\n')
            f.writelines(hero_and_analytics)

move_classes()

# Fix visibility in dashboard
def fix_dashboard():
    dash_path = os.path.join(lib_dir, "admin_dashboard_screen.dart")
    with open(dash_path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('_AdminWelcomeHero', 'AdminWelcomeHero')
    content = content.replace('_AnalyticsCard', 'AdminAnalyticsCard')
    with open(dash_path, 'w', encoding='utf-8') as f:
        f.write(content)

fix_dashboard()

print("Imports and class moved.")
