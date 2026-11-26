"""Draws the Google Play feature image (1024 x 500, variant B of the canvas:
night, the name and slogan on the left, the home screen on the right) and the
store icon (512 x 512) (backlog/fiche-google-play.md). Not part of the checks.

  python3 tool/play_graphics.py <home-capture.png> <out-dir>

The home capture is the 1-accueil.png taken for tool/play_screens.py. Writes
<out-dir>/feature-graphic.png and <out-dir>/icon-512.png. Needs Google Chrome,
run headless.
"""
import base64
import os
import subprocess
import sys

HOME, OUT = sys.argv[1], sys.argv[2]
FONTS = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', 'assets', 'fonts'))
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

HEAD = """<!doctype html><html lang="fr"><head><meta charset="utf-8"><style>
@font-face{{font-family:Inter;src:url(file://{fonts}/Inter.ttf)}}
@font-face{{font-family:'Plus Jakarta Sans';src:url(file://{fonts}/PlusJakartaSans.ttf)}}
@font-face{{font-family:'Space Grotesk';src:url(file://{fonts}/SpaceGrotesk.ttf)}}
html,body{{margin:0;overflow:hidden}}
</style></head><body>"""

FEATURE = """<div style="width: 1024px; height: 500px; overflow: hidden; position: relative; background: #0E1320; font-family: Inter, sans-serif">
  <div style="position: absolute; left: 72px; top: 0; bottom: 0; width: 560px; display: flex; flex-direction: column; justify-content: center; gap: 22px">
    <div style="display: flex; align-items: center; gap: 16px"><svg viewBox="0 0 96 96" width="64" height="64" aria-hidden="true"><rect width="96" height="96" rx="22" fill="#1C2333"></rect><circle cx="48" cy="48" r="25" fill="#5EEAB5"></circle><path d="M42 35A10 10 0 1 1 54 35Z" fill="#FFC247" stroke="#0E1320" stroke-width="2.5"></path><path d="M45 28.5h6" stroke="#0E1320" stroke-width="1.8" stroke-linecap="round" opacity="0.45"></path><rect x="37" y="35" width="22" height="5" rx="2.5" fill="#0E1320"></rect></svg><span role="img" aria-label="kibuo" style="font: 700 60px/1.2 'Space Grotesk', sans-serif; letter-spacing: -0.75px; color: #FFFFFF">k<span style="position: relative; display: inline-block">ı<span style="position: absolute; left: 50%; top: 6.0px; width: 16.2px; height: 16.2px; margin-left: -8.1px; box-sizing: border-box; border-radius: 50%; background: #FFC247; border: 2.7px solid #0E1320"></span></span>buo</span></div>
    <p style="margin: 0; font: 700 38px/48px 'Plus Jakarta Sans', sans-serif; letter-spacing: -0.01em; color: #FFFFFF">Votre compagnon, des dépenses quotidiennes à vos projets.</p>
    <div style="display: flex; flex-wrap: nowrap; gap: 8px"><span style="display: inline-flex; align-items: center; gap: 6px; padding: 7px 13px 7px 10px; border-radius: 999px; background: rgba(94,234,181,0.12); box-shadow: inset 0 0 0 1px rgba(94,234,181,0.35); color: #5EEAB5; font: 600 17px Inter, sans-serif; white-space: nowrap"><svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 4v13M6 11l6 6 6-6M5 20h14"/></svg>Dépenses</span><span style="display: inline-flex; align-items: center; gap: 6px; padding: 7px 13px 7px 10px; border-radius: 999px; background: rgba(94,234,181,0.12); box-shadow: inset 0 0 0 1px rgba(94,234,181,0.35); color: #5EEAB5; font: 600 17px Inter, sans-serif; white-space: nowrap"><svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3a9 9 0 1 0 9 9h-9z"/><path d="M15 2.6V9h6.4A9 9 0 0 0 15 2.6z"/></svg>Budgets</span><span style="display: inline-flex; align-items: center; gap: 6px; padding: 7px 13px 7px 10px; border-radius: 999px; background: rgba(94,234,181,0.12); box-shadow: inset 0 0 0 1px rgba(94,234,181,0.35); color: #5EEAB5; font: 600 17px Inter, sans-serif; white-space: nowrap"><svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 8h13l-3-3M20 16H7l3 3"/></svg>Dettes</span><span style="display: inline-flex; align-items: center; gap: 6px; padding: 7px 13px 7px 10px; border-radius: 999px; background: rgba(94,234,181,0.12); box-shadow: inset 0 0 0 1px rgba(94,234,181,0.35); color: #5EEAB5; font: 600 17px Inter, sans-serif; white-space: nowrap"><svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1" fill="currentColor"/></svg>Projets</span></div>
  </div>
  <div style="position: absolute; left: 676px; top: 56px; width: 300px; height: 640px; border-radius: 40px; background: #1C2333; padding: 10px; box-sizing: border-box">
    <div style="height: 620px; border-radius: 30px; overflow: hidden; background: #EEF1F7"><img src="{img}" alt="Accueil de kibuo" style="display: block; width: 280px; margin-top: -26px"></div>
  </div>
</div>"""

# The store icon: Google Play rounds the corners itself, so the square is
# full; the drawing is the app's logo (BRAND.md).
ICON = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" width="512" height="512" style="display:block">
<rect width="96" height="96" fill="#0E1320"/>
<circle cx="48" cy="48" r="25" fill="#5EEAB5"/>
<path d="M42 35A10 10 0 1 1 54 35Z" fill="#FFC247" stroke="#0E1320" stroke-width="2.5"/>
<path d="M45 28.5h6" stroke="#0E1320" stroke-width="1.8" stroke-linecap="round" opacity="0.45"/>
<rect x="37" y="35" width="22" height="5" rx="2.5" fill="#0E1320"/>
</svg>"""


def shoot(html, name, width, height):
    path = os.path.join(OUT, name + '.html')
    open(path, 'w', encoding='utf-8').write(html)
    png = os.path.abspath(os.path.join(OUT, name + '.png'))
    subprocess.run([CHROME, '--headless=new', '--disable-gpu',
                    '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--allow-file-access-from-files',
                    f'--window-size={width},{height}', f'--screenshot={png}',
                    'file://' + os.path.abspath(path)],
                   check=True, capture_output=True)
    os.remove(path)
    print('written', png)


os.makedirs(OUT, exist_ok=True)
img = 'data:image/png;base64,' + base64.b64encode(open(HOME, 'rb').read()).decode()
head = HEAD.format(fonts=FONTS)
shoot(head + FEATURE.format(img=img) + '</body></html>', 'feature-graphic', 1024, 500)
shoot(head + ICON + '</body></html>', 'icon-512', 512, 512)
