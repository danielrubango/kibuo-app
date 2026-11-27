"""Pieces for drawing kibuo boards for the design canvas (.dc.html).

A board is one phone screen, 390 by 844, in the file format of the canvas's
Design type. Colours come from the app's own tokens
(lib/ui/theme/kibuo_colors.dart), so a board and the app cannot drift.

    import sys; sys.path.insert(0, 'tool/boards'); from kit import *
    html = shell('Compte · B', page_head('M-Pesa', 'Novembre 2026') + card(big('162,10 $')))
    write(project, 'CompteB', html)
    place(project, [('CompteB', 'Compte B · le solde en grand', 0)], y=8300)

See README.md in this folder for the canvas, fetching and publishing.
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _colors():
    src = open(os.path.join(ROOT, 'lib/ui/theme/kibuo_colors.dart')).read()
    return {name: '#' + argb[2:]
            for name, argb in re.findall(r'static const (\w+) = Color\(0x([0-9A-Fa-f]{8})\)', src)}


#: The app's colours by their Dart name: C['ink'], C['accent'], C['debtTint']…
C = _colors()

DISPLAY = "'Plus Jakarta Sans', sans-serif"

#: Line icons, 24 by 24 paths drawn with a 1.9 stroke (Phosphor-like).
ICONS = {
    'home': 'M4 11l8-7 8 7v9H4z',
    'list': 'M5 7h14M5 12h14M5 17h14',
    'chart': 'M5 20V10M10 20V5M15 20v-8M20 20H4',
    'grid': 'M5 5h5v5H5zM14 5h5v5h-5zM5 14h5v5H5zM14 14h5v5h-5z',
    'plus': 'M12 5v14M5 12h14',
    'basket': 'M5 7h14l-2 10H7zM9 7a3 3 0 0 1 6 0',
    'fork': 'M7 3v8M5 3v5a2 2 0 0 0 4 0V3M17 3v18M17 3c-2 0-3 3-3 6s1 3 3 3',
    'bus': 'M5 17V8a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v9M5 13h14M8 17v2M16 17v2',
    'dots': 'M6 12h.01M12 12h.01M18 12h.01',
    'cup': 'M5 8h11v5a5 5 0 0 1-5 5h-1a5 5 0 0 1-5-5zM16 10h2a2 2 0 0 1 0 4h-2',
    'wallet': 'M4 7h14a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4zM4 7V6a2 2 0 0 1 2-2h10M16 13h.01',
    'arrows': 'M7 7h12l-3-3M17 17H5l3 3',
    'back': 'M15 6l-6 6 6 6',
    'caret': 'M9 6l6 6-6 6',
    'up': 'M6 15l6-6 6 6',
    'down': 'M6 9l6 6 6-6',
}


def svg(name, size=20, color='currentColor', width=1.9):
    return (f'<svg viewBox="0 0 24 24" width="{size}" height="{size}" fill="none" stroke="{color}" '
            f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"><path d="{ICONS[name]}"/></svg>')


def tile(icon, color, size=40):
    """An icon on its coloured square, as category and account tiles."""
    return (f'<span style="flex: 0 0 {size}px; width: {size}px; height: {size}px; border-radius: {round(size * 0.32)}px; '
            f'background: {color}; display: flex; align-items: center; justify-content: center; color: {C["ink"]}">'
            f'{svg(icon, round(size * 0.55))}</span>')


def bar(share, color, h=6):
    """A share bar: [share] percent of the track."""
    return (f'<span style="display: block; height: {h}px; border-radius: {h // 2}px; background: {C["track"]}; overflow: hidden">'
            f'<span style="display: block; width: {share}%; height: {h}px; border-radius: {h // 2}px; background: {color}"></span></span>')


def card(*children, gap=8):
    """A white card, 18 round, 14 by 16 inside."""
    return (f'<section style="background: {C["surface"]}; border-radius: 18px; padding: 14px 16px; '
            f'display: flex; flex-direction: column; gap: {gap}px">' + ''.join(children) + '</section>')


def big(text, color=None):
    return f'<b style="font-family: {DISPLAY}; font-size: 30px; color: {color or C["ink"]}">{text}</b>'


def small(text):
    return f'<span style="font-size: 13px; color: {C["inkSecondary"]}">{text}</span>'


def group(title, *children):
    """A group title, 8 above its card; groups stand 20 apart (DIRECTION, Groupes)."""
    return (f'<div style="display: flex; flex-direction: column; gap: 8px; margin-top: 6px">'
            f'<span style="font-size: 13px; font-weight: 600; color: {C["inkSecondary"]}; padding: 0 4px">{title}</span>'
            + ''.join(children) + '</div>')


def page_head(name, sub, icon='wallet', color=None):
    """The top of a pushed page: back, a tile, the name and a grey line."""
    return (f'<header style="display: flex; align-items: center; gap: 10px; min-height: 44px">'
            f'<span style="width: 40px; height: 44px; display: flex; align-items: center; justify-content: center; margin-left: -8px">'
            f'{svg("back", 22)}</span>{tile(icon, color or C["mint"], 36)}'
            f'<span style="display: flex; flex-direction: column"><b style="font-size: 18px">{name}</b>'
            f'<span style="font-size: 12px; color: {C["inkSecondary"]}">{sub}</span></span></header>')


_NAV = [('Accueil', 'home'), ('Opérations', 'list'), None, ('Aperçu', 'chart'), ('Plus', 'grid')]


def _nav(active):
    cells = ''
    for item in _NAV:
        if item is None:
            cells += (f'<span style="width: 64px; height: 64px; border-radius: 22px; background: {C["mint"]}; margin-top: -26px; '
                      f'display: flex; align-items: center; justify-content: center; box-shadow: 0 0 0 6px {C["background"]}">'
                      f'{svg("plus", 28, C["ink"], 2.4)}</span>')
            continue
        label, icon = item
        on = label == active
        cells += (f'<span style="display: flex; flex-direction: column; align-items: center; gap: 4px; font-size: 11px; '
                  f'font-weight: 600; color: {C["accent"] if on else C["inkSecondary"]}">'
                  f'<span style="width: 48px; height: 28px; border-radius: 14px; background: {C["mint"] if on else "transparent"}; '
                  f'display: flex; align-items: center; justify-content: center; color: {C["ink"]}">{svg(icon)}</span>{label}</span>')
    return (f'<div style="position: absolute; left: 12px; right: 12px; bottom: 22px; height: 64px; background: {C["surface"]}; '
            f'border-radius: 26px; box-shadow: 0 8px 24px rgba(14,19,32,0.12); display: flex; align-items: center; '
            f'justify-content: space-around">{cells}</div>')


def shell(title, body, nav=None, w=390, h=844):
    """A whole board: the phone screen with [body] stacked 14 apart, and the
    bottom bar with [nav] (« Aperçu », « Accueil »…) chosen, or none."""
    return f'''<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>{title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=Plus+Jakarta+Sans:wght@600;700;800&amp;display=swap">
<style>body{{margin:0}}</style>
</helmet>
<div style="width: {w}px; height: {h}px; position: relative; overflow: hidden; background: {C["background"]}; color: {C["ink"]}; font-family: Inter, sans-serif">
<div style="box-sizing: border-box; padding: 16px 16px 112px; display: flex; flex-direction: column; gap: 14px">{body}</div>
{_nav(nav) if nav else ''}
</div>
</x-dc>
</body>
</html>
'''


def write(project, name, html):
    """Writes [name].dc.html into the canvas's project folder."""
    with open(os.path.join(project, name + '.dc.html'), 'w') as f:
        f.write(html)


def place(project, boards, y, page='en-cours', note=None, w=390, h=844):
    """Puts each (name, title, x) on [page] at height [y] in canvas.json,
    with an optional (key, text) title 260 above. Titles end with
    « (retenue) » or « (non retenue) » once the owner has chosen."""
    path = os.path.join(project, 'canvas.json')
    canvas = json.load(open(path))
    for name, title, x in boards:
        canvas['boards'][name + '.dc.html'] = {'h': h, 'page': page, 'w': w, 'x': x, 'y': y, 'title': title}
        if name + '.dc.html' not in canvas['order']:
            canvas['order'].append(name + '.dc.html')
    if note:
        key, text = note
        canvas['notes'][key] = {'kind': 'title1', 'maxW': max(x for _, _, x in boards) + w, 'page': page,
                                'x': 0, 'y': y - 260, 'text': text}
    json.dump(canvas, open(path, 'w'), ensure_ascii=False, indent=1)
