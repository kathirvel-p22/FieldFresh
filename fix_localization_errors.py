#!/usr/bin/env python3
"""
Script to fix localization errors by replacing S.of(context) calls with LocalizationHelper.getText calls
"""

import os
import re

def fix_file(file_path):
    """Fix localization errors in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Add import if not present
        if 'import \'../../../utils/localization_helper.dart\';' not in content and 'LocalizationHelper' not in content:
            # Find the last import line
            import_lines = []
            other_lines = []
            in_imports = True
            
            for line in content.split('\n'):
                if line.startswith('import ') and in_imports:
                    import_lines.append(line)
                else:
                    if in_imports and line.strip() and not line.startswith('//'):
                        in_imports = False
                    other_lines.append(line)
            
            # Add the import
            import_lines.append('import \'../../../utils/localization_helper.dart\';')
            content = '\n'.join(import_lines + other_lines)
        
        # Replace S.of(context) calls with LocalizationHelper.getText calls
        patterns = [
            # Simple property access
            (r'S\.of\(context\)\.(\w+)', r'LocalizationHelper.getText(context, \'\1\')'),
            # Method calls with parameters
            (r'S\.of\(context\)\.resendInSeconds\(([^)]+)\)', r'LocalizationHelper.getTextWithParams(context, \'resendInSeconds\', seconds: \1)'),
            (r'S\.of\(context\)\.validForHours\(([^)]+)\)', r'LocalizationHelper.getTextWithParams(context, \'validForHours\', hours: \1)'),
            (r'S\.of\(context\)\.aiSuggestionText\(([^,]+),\s*([^)]+)\)', r'LocalizationHelper.getTextWithParams(context, \'aiSuggestionText\', category: \1, hours: \2)'),
            (r'S\.of\(context\)\.expiresAt\(([^)]+)\)', r'LocalizationHelper.getTextWithParams(context, \'expiresAt\', category: \1)'),
            (r'S\.of\(context\)\.noStatusOrders\(([^)]+)\)', r'LocalizationHelper.getTextWithParams(context, \'noStatusOrders\', category: \1)'),
        ]
        
        for pattern, replacement in patterns:
            content = re.sub(pattern, replacement, content)
        
        # Remove generated l10n import if present
        content = re.sub(r'import \'[^\']*generated/l10n\.dart\';\n?', '', content)
        
        # Write back if changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {file_path}")
            return True
        else:
            print(f"No changes needed: {file_path}")
            return False
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to fix all files"""
    files_to_fix = [
        'lib/features/auth/otp_screen.dart',
        'lib/features/farmer/farmer_home.dart',
        'lib/features/customer/customer_home.dart',
        'lib/features/farmer/post_product/post_product_screen.dart',
        'lib/features/farmer/profile/farmer_profile_screen.dart',
        'lib/features/customer/profile/customer_profile_screen.dart',
    ]
    
    fixed_count = 0
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_file(file_path):
                fixed_count += 1
        else:
            print(f"File not found: {file_path}")
    
    print(f"\nFixed {fixed_count} files")

if __name__ == "__main__":
    main()