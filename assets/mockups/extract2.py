import re
import sys

def get_text(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        html = f.read()

    html = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', html, flags=re.IGNORECASE | re.DOTALL)
    text = re.sub(r'<[^>]+>', ' ', html)
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    return '\n'.join(lines)

print(get_text('/run/media/morph/E8EC-C477/Site Backups/steamy/Community.html'))
