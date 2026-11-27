"""Worked example: the three ways to show today on an account's curve
(J1, J2, J3; J3 retained on 28 November 2026). Draws the boards, then
places them on the « En cours » page.

    python3 tool/boards/jour.py <canvas project folder>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import C, big, card, group, page_head, place, shell, tile, write  # noqa: E402

GREEN, BROWN, BLUE = C['accent'], C['debtInk'], C['projectInk']

# M-Pesa in November, today the 12th: 320 $ on the 1st, −190,40 on the 7th,
# −55,50 on the 10th, +288 on the 12th. One point per day's end.
VALUES = [320] * 7 + [129.6] * 3 + [74.1] * 2 + [362.1]
DAYS, W, H = 30, 326, 96


def curve(marker, dot=False):
    """The balance line up to today, [marker] behind it, the axis under."""
    low, top = min(VALUES), max(VALUES)
    pts = [(i * W / DAYS, 6 + (H - 12) * (1 - (v - low) / (top - low))) for i, v in enumerate(VALUES)]
    path = f'M{pts[0][0]:.1f} {pts[0][1]:.1f}'
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        dx = (x1 - x0) / 2
        path += f' C{x0 + dx:.1f} {y0:.1f} {x1 - dx:.1f} {y1:.1f} {x1:.1f} {y1:.1f}'
    tx, ty = pts[-1]
    out = (f'<svg viewBox="0 0 {W} {H}" width="100%" height="{H}" style="display: block; overflow: visible">'
           f'{marker(tx)}<path d="{path}" fill="none" stroke="{GREEN}" stroke-width="2.2" stroke-linecap="round"/>')
    if dot:
        out += f'<circle cx="{tx}" cy="{ty:.1f}" r="4.5" fill="{GREEN}" stroke="#FFFFFF" stroke-width="2"/>'
    out += '</svg>'
    return out + (f'<div style="position: relative; height: 16px; margin-top: 6px; font-size: 11px; color: {C["inkMuted"]}">'
                  f'<span style="position: absolute; left: 0">1er</span>'
                  f'<span style="position: absolute; left: {tx / W * 100:.1f}%; transform: translateX(-50%); '
                  f'color: {C["inkSecondary"]}; font-weight: 600">12 nov.</span>'
                  f'<span style="position: absolute; right: 0">30</span></div>')


def line(x):
    return f'<line x1="{x}" y1="0" x2="{x}" y2="{H}" stroke="{C["ink"]}" stroke-opacity="0.14" stroke-width="2"/>'


def tick(x):
    return f'<line x1="{x}" y1="{H - 8}" x2="{x}" y2="{H + 2}" stroke="{C["ink"]}" stroke-width="2.2" stroke-linecap="round"/>'


OPS = [('Jeudi 12 novembre', [('in', 'Salaire', '09:10', '+300,00 $'), ('out', 'Repas', '13:05', '−12,00 $')]),
       ('Mardi 10 novembre', [('move', 'Vers Espèces', '18:20', '−50,00 $'), ('out', 'Taxi', '08:40', '−5,50 $')]),
       ('Samedi 7 novembre', [('out', 'Courses', '17:30', '−190,40 $')])]
KIND = {'in': ('basket', C['accentTint'], GREEN), 'out': ('fork', C['debtTint'], BROWN),
        'move': ('arrows', C['projectTint'], BLUE)}


def operations():
    out = ''
    for day, items in OPS:
        rows = ''
        for i, (kind, name, time, amount) in enumerate(items):
            icon, tint, ink = KIND[kind]
            sep = f'border-top: 1px solid {C["background"]};' if i else ''
            rows += (f'<span style="display: flex; align-items: center; gap: 12px; min-height: 56px; {sep}">{tile(icon, tint, 36)}'
                     f'<span style="flex: 1 1 auto; display: flex; flex-direction: column">'
                     f'<span style="font-size: 15px; font-weight: 600">{name}</span>'
                     f'<span style="font-size: 12px; color: {C["inkSecondary"]}">M-Pesa · {time}</span></span>'
                     f'<b style="font-size: 15px; color: {ink}">{amount}</b></span>')
        out += group(day, f'<section style="background: {C["surface"]}; border-radius: 18px; padding: 2px 16px">{rows}</section>')
    return out


def board(title, marker, dot=False):
    pair = (f'<span style="display: flex; gap: 8px; margin-top: 4px">'
            f'<span style="flex: 1 1 0; border-radius: 12px; background: {C["accentTint"]}; padding: 8px 10px; display: flex; flex-direction: column">'
            f'<span style="font-size: 12px; color: {C["inkSecondary"]}">Entrées</span><b style="color: {GREEN}">+300,00 $</b></span>'
            f'<span style="flex: 1 1 0; border-radius: 12px; background: {C["debtTint"]}; padding: 8px 10px; display: flex; flex-direction: column">'
            f'<span style="font-size: 12px; color: {C["inkSecondary"]}">Sorties</span><b style="color: {BROWN}">−257,90 $</b></span></span>')
    return shell(title, page_head('M-Pesa', 'Novembre 2026') + card(
        big('362,10 $'),
        f'<span style="font-size: 13px; font-weight: 700; color: {GREEN}; margin-top: -6px">+42,10 $ ce mois-ci</span>',
        '<span style="height: 4px"></span>',
        curve(marker, dot), pair,
    ) + operations())


if __name__ == '__main__':
    project = sys.argv[1]
    boards = [
        ('JourJ1', board('J1 · trait vertical léger', line),
         'J1 · un trait vertical à 14 % d’encre, de haut en bas, sous lequel la date du jour (non retenue)', 0),
        ('JourJ2', board('J2 · petite barre', tick),
         'J2 · une petite barre foncée en bas de la courbe, comme sur la carte du mois de l’Accueil (non retenue)', 470),
        ('JourJ3', board('J3 · trait léger et point', line, dot=True),
         'J3 · le trait léger de J1, et un point sur la courbe à la valeur du jour (retenue)', 940),
    ]
    for name, html, _, _ in boards:
        write(project, name, html)
    if os.path.exists(os.path.join(project, 'canvas.json')):
        place(project, [(n, t, x) for n, _, t, x in boards], y=9500,
              note=('titreJour', 'Page d’un compte · montrer le jour sur la courbe · J3 retenue'))
