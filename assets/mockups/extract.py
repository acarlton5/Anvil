import re

with open('/run/media/morph/E8EC-C477/Site Backups/steamy/Library_play_view.html', 'r', encoding='utf-8') as f:
    html = f.read()

html = re.sub(r'<(script|style)[^>]*>.*?</\1>', ' ', html, flags=re.IGNORECASE | re.DOTALL)
text = re.sub(r'<[^>]+>', ' ', html)
lines = [line.strip() for line in text.split('\n') if line.strip()]

print('\n'.join(lines))
