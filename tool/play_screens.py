"""Composes the Google Play phone screenshots, style A (night background,
a sentence on top, the screen in a phone frame), at 1080 x 1920
(backlog/fiche-google-play.md). Not part of the checks.

  python3 tool/play_screens.py <shots-dir> <out-dir>

Each emulator capture <n>-<name>.png (1080 x 2424, taken on a test Android
user restored from tool/demo_backup_test.dart) gives <out-dir>/<n>-<name>.png.
The phone's own status bar is cut off and drawn again as grey dashes, so the
image belongs to no system in particular. Needs Google Chrome, run headless.
"""
import base64
import os
import subprocess
import sys

SHOTS, OUT = sys.argv[1], sys.argv[2]
FONTS = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', 'assets', 'fonts'))
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

TEXTS = {
    '1-accueil': ('Ce que vous pouvez dépenser, d’un coup d’œil.',
                  'Votre disponible, le mois en cours et ce qui attend.'),
    '2-saisie': ('Une dépense notée en quelques touches.',
                 'Le bouton + est toujours là, même sans connexion.'),
    '3-operations': ('Tout votre mois,<br>jour après jour.',
                     'Entrées, sorties et ce qui reste.'),
    '4-budgets': ('Des budgets qui vous préviennent à temps.',
                  'Une alerte quand une catégorie approche de sa limite.'),
    '5-dettes': ('Ce que vous devez,<br>ce qu’on vous doit.',
                 'Les échéances, les retards et les remboursements.'),
    '6-projets': ('Mettez de côté pour vos projets.',
                  'Voyage, moto, rentrée : voyez où vous en êtes.'),
}

PAGE = """<!doctype html><html lang="fr"><head><meta charset="utf-8"><style>
@font-face{{font-family:Inter;src:url(file://{fonts}/Inter.ttf)}}
@font-face{{font-family:Jakarta;src:url(file://{fonts}/PlusJakartaSans.ttf)}}
html,body{{margin:0;width:1080px;height:1920px;overflow:hidden;background:#0E1320}}
.t{{padding:120px 96px 0;display:flex;flex-direction:column;gap:24px}}
h1{{margin:0;font:700 68px/1.12 Jakarta,sans-serif;letter-spacing:-0.02em;color:#fff}}
p{{margin:0;font:400 36px/48px Inter,sans-serif;color:#B9C1D1}}
.f{{margin:88px auto 0;width:820px;height:1840px;border-radius:72px;background:#1C2333;padding:14px;box-sizing:border-box}}
.s{{border-radius:60px;overflow:hidden;height:1812px;background:#EEF1F7}}
.sc{{overflow:hidden;height:1736px}}
.sc img{{display:block;width:792px;margin-top:-100px}}
.sb{{position:relative;height:76px;padding:0 44px 0 52px;display:flex;align-items:center;justify-content:space-between;background:#EEF1F7;font:600 26px Inter,sans-serif;color:#0E1320}}
.sb .ic{{display:flex;align-items:center;gap:12px}}
.sb i{{display:block;height:14px;border-radius:7px;background:#B6BDCB}}
.sb .cam{{position:absolute;left:50%;top:50%;width:28px;height:28px;margin:-14px 0 0 -14px;border-radius:50%;background:#0E1320}}
</style></head><body><div class="t"><h1>{title}</h1><p>{sub}</p></div>
<div class="f"><div class="s"><div class="sb"><b class="cam"></b><i style="width:58px"></i><span class="ic"><i style="width:26px"></i><i style="width:26px"></i><i style="width:40px"></i></span></div><div class="sc"><img src="data:image/png;base64,{img}"></div></div></div></body></html>"""

os.makedirs(OUT, exist_ok=True)
for name, (title, sub) in TEXTS.items():
    shot = os.path.join(SHOTS, name + '.png')
    if not os.path.exists(shot):
        print('missing', shot)
        continue
    img = base64.b64encode(open(shot, 'rb').read()).decode()
    html_path = os.path.join(OUT, name + '.html')
    open(html_path, 'w', encoding='utf-8').write(
        PAGE.format(fonts=FONTS, title=title, sub=sub, img=img))
    png = os.path.abspath(os.path.join(OUT, name + '.png'))
    subprocess.run([CHROME, '--headless=new', '--disable-gpu',
                    '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files',
                    '--window-size=1080,1920', f'--screenshot={png}',
                    'file://' + os.path.abspath(html_path)],
                   check=True, capture_output=True)
    os.remove(html_path)
    print('written', png)
