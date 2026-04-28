import os
import re

count = 0
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace catch (_) {} with logging
            new_content = re.sub(r'catch \([_e]\) \{\s*\}', r"catch (e) { debugPrint('Silent error caught: $e'); }", content)
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                count += 1
                print(f"Fixed {path}")

print(f"Replaced silent catches in {count} files.")
