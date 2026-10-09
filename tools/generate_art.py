#!/usr/bin/env python3
"""
Gera a pixel art PROVISORIA (placeholder) de EXTINCT: BRASIL.
Todo o visual e criado por codigo: nenhum asset de terceiros.

Uso (na raiz do projeto):  python3 tools/generate_art.py
Requer: pip install pillow
Depois voce pode substituir qualquer PNG por arte propria, mantendo o nome
e o tamanho do arquivo.
"""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = 16


def rgb(r, g, b, a=255):
    return (r, g, b, a)


# ------------------------------------------------------------------ TILES
GRASS = rgb(96, 168, 78)
GRASS_D = rgb(76, 146, 64)
GRASS_L = rgb(124, 192, 98)


def tile_grass(seed=1):
    rnd = random.Random(seed)
    im = Image.new("RGBA", (T, T), GRASS)
    d = ImageDraw.Draw(im)
    for _ in range(14):
        x, y = rnd.randrange(T), rnd.randrange(T)
        d.point((x, y), fill=rnd.choice([GRASS_D, GRASS_L]))
    return im


def tile_tall():
    im = tile_grass(2)
    d = ImageDraw.Draw(im)
    dark, mid, light = rgb(40, 112, 48), rgb(58, 138, 60), rgb(150, 210, 110)
    for bx in (2, 6, 10, 13):
        for by in (5, 12):
            d.line([(bx, by), (bx - 1, by - 4)], fill=dark)
            d.line([(bx, by), (bx, by - 5)], fill=mid)
            d.line([(bx, by), (bx + 1, by - 4)], fill=dark)
            d.point((bx, by - 5), fill=light)
    return im


def tile_path():
    rnd = random.Random(3)
    base = rgb(206, 176, 116)
    im = Image.new("RGBA", (T, T), base)
    d = ImageDraw.Draw(im)
    for _ in range(18):
        d.point((rnd.randrange(T), rnd.randrange(T)),
                fill=rnd.choice([rgb(186, 156, 100), rgb(222, 194, 138)]))
    return im


def tile_tree():
    im = tile_grass(4)
    d = ImageDraw.Draw(im)
    d.rectangle([7, 10, 9, 15], fill=rgb(110, 72, 42))
    d.ellipse([1, 0, 14, 12], fill=rgb(30, 100, 52))
    d.ellipse([3, 1, 11, 7], fill=rgb(46, 126, 62))
    d.ellipse([4, 2, 7, 4], fill=rgb(90, 170, 90))
    d.arc([1, 0, 14, 12], 20, 160, fill=rgb(20, 70, 40))
    return im


def tile_water():
    base = rgb(60, 124, 200)
    im = Image.new("RGBA", (T, T), base)
    d = ImageDraw.Draw(im)
    for (x, y) in [(2, 3), (9, 7), (4, 12), (11, 1)]:
        d.line([(x, y), (x + 3, y)], fill=rgb(150, 196, 240))
    for (x, y) in [(6, 5), (1, 9), (12, 11)]:
        d.line([(x, y), (x + 2, y)], fill=rgb(40, 96, 170))
    return im


def tile_wall():
    base = rgb(214, 202, 178)
    im = Image.new("RGBA", (T, T), base)
    d = ImageDraw.Draw(im)
    line = rgb(168, 154, 128)
    for y in (0, 5, 10):
        d.line([(0, y), (T, y)], fill=line)
    for y, off in ((0, 4), (5, 10), (10, 4)):
        d.line([(off, y), (off, y + 4)], fill=line)
    d.line([(0, 15), (T, 15)], fill=rgb(140, 126, 102))
    return im


def tile_roof():
    base = rgb(176, 62, 52)
    im = Image.new("RGBA", (T, T), base)
    d = ImageDraw.Draw(im)
    for y in (3, 7, 11, 15):
        d.line([(0, y), (T, y)], fill=rgb(128, 40, 36))
    for y in (1, 5, 9, 13):
        d.line([(0, y), (T, y)], fill=rgb(204, 90, 74))
    return im


def tile_door():
    im = tile_wall()
    d = ImageDraw.Draw(im)
    d.rectangle([3, 1, 12, 15], fill=rgb(96, 60, 34))
    d.rectangle([4, 2, 11, 15], fill=rgb(130, 84, 48))
    d.line([(7, 2), (7, 15)], fill=rgb(96, 60, 34))
    d.line([(8, 2), (8, 15)], fill=rgb(96, 60, 34))
    d.point((10, 9), fill=rgb(240, 210, 90))
    return im


def tile_floor():
    base = rgb(196, 186, 164)
    im = Image.new("RGBA", (T, T), base)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 15, 15], outline=rgb(172, 162, 140))
    d.point((4, 4), fill=rgb(214, 206, 186))
    d.point((11, 11), fill=rgb(214, 206, 186))
    return im


def tile_machine():
    im = tile_floor()
    d = ImageDraw.Draw(im)
    d.rectangle([1, 2, 14, 14], fill=rgb(52, 64, 98))
    d.rectangle([1, 2, 14, 14], outline=rgb(30, 38, 62))
    d.rectangle([3, 4, 12, 9], fill=rgb(80, 220, 196))
    d.line([(4, 6), (8, 6)], fill=rgb(30, 120, 110))
    d.line([(4, 8), (10, 8)], fill=rgb(30, 120, 110))
    d.point((3, 12), fill=rgb(240, 90, 70))
    d.point((6, 12), fill=rgb(250, 220, 80))
    d.point((9, 12), fill=rgb(100, 240, 120))
    return im


def tile_mat():
    im = tile_floor()
    d = ImageDraw.Draw(im)
    d.rectangle([1, 3, 14, 15], fill=rgb(150, 56, 56))
    d.rectangle([2, 4, 13, 15], outline=rgb(220, 190, 110))
    return im


def tile_portal():
    im = tile_grass(5)
    d = ImageDraw.Draw(im)
    d.ellipse([1, 1, 14, 14], fill=rgb(30, 40, 120))
    d.ellipse([2, 2, 13, 13], fill=rgb(70, 110, 220))
    d.ellipse([4, 4, 11, 11], fill=rgb(130, 220, 250))
    d.ellipse([6, 6, 9, 9], fill=rgb(240, 255, 255))
    d.line([(3, 8), (6, 5)], fill=rgb(200, 240, 255))
    d.line([(12, 8), (9, 11)], fill=rgb(200, 240, 255))
    return im


def tile_sign():
    im = tile_grass(6)
    d = ImageDraw.Draw(im)
    d.rectangle([7, 8, 8, 15], fill=rgb(96, 62, 36))
    d.rectangle([2, 2, 13, 9], fill=rgb(170, 120, 70))
    d.rectangle([2, 2, 13, 9], outline=rgb(96, 62, 36))
    d.line([(4, 4), (11, 4)], fill=rgb(96, 62, 36))
    d.line([(4, 6), (10, 6)], fill=rgb(96, 62, 36))
    return im


def tile_rock():
    im = tile_grass(7)
    d = ImageDraw.Draw(im)
    d.ellipse([1, 4, 14, 15], fill=rgb(110, 110, 118))
    d.ellipse([2, 4, 12, 12], fill=rgb(150, 150, 158))
    d.ellipse([4, 5, 8, 8], fill=rgb(190, 190, 198))
    return im


def tile_labwall():
    base = rgb(96, 112, 140)
    im = Image.new("RGBA", (T, T), base)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 15, 15], outline=rgb(66, 80, 106))
    d.rectangle([2, 2, 13, 13], outline=rgb(120, 136, 164))
    d.point((3, 3), fill=rgb(200, 210, 230))
    d.point((12, 12), fill=rgb(200, 210, 230))
    return im


TILES = [tile_grass, tile_tall, tile_path, tile_tree, tile_water, tile_wall,
         tile_roof, tile_door, tile_floor, tile_machine, tile_mat, tile_portal,
         tile_sign, tile_rock, tile_labwall]


def make_tileset():
    sheet = Image.new("RGBA", (T * len(TILES), T))
    for i, fn in enumerate(TILES):
        sheet.paste(fn(), (i * T, 0))
    sheet.save(os.path.join(ROOT, "Assets/Tiles/tileset.png"))


# ------------------------------------------------------------- CHARACTERS
def draw_frame(im, ox, oy, direction, step, skin, hair, shirt, pants, pack):
    d = ImageDraw.Draw(im)
    dark = rgb(30, 28, 40)
    shoe = rgb(60, 44, 36)
    leg_l = 12 if step != 1 else 11
    leg_r = 12 if step != 2 else 11

    def R(x0, y0, x1, y1, c):
        d.rectangle([ox + x0, oy + y0, ox + x1, oy + y1], fill=c)

    if direction == "down":
        R(5, 1, 10, 4, hair)
        R(5, 4, 10, 7, skin)
        R(6, 5, 6, 5, dark)
        R(9, 5, 9, 5, dark)
        R(4, 8, 11, 12, shirt)
        R(3, 8, 3, 11, shirt)
        R(12, 8, 12, 11, shirt)
        R(3, 12, 3, 12, skin)
        R(12, 12, 12, 12, skin)
        R(5, leg_l, 7, 14, pants)
        R(8, leg_r, 10, 14, pants)
        R(5, 15, 7, 15, shoe)
        R(8, 15, 10, 15, shoe)
    elif direction == "up":
        R(5, 1, 10, 7, hair)
        R(4, 8, 11, 12, pack)
        R(5, 9, 10, 12, shirt)
        R(3, 8, 3, 11, shirt)
        R(12, 8, 12, 11, shirt)
        R(5, leg_l, 7, 14, pants)
        R(8, leg_r, 10, 14, pants)
        R(5, 15, 7, 15, shoe)
        R(8, 15, 10, 15, shoe)
    else:  # "left" (o "right" e espelhado)
        R(5, 1, 10, 4, hair)
        R(5, 4, 9, 7, skin)
        R(10, 4, 10, 7, hair)
        R(5, 5, 5, 5, dark)
        R(11, 8, 12, 12, pack)
        R(5, 8, 10, 12, shirt)
        R(6, 9, 8, 11, shirt)
        R(6, 12, 9, 12, skin if False else shirt)
        lf = 12 if step != 1 else 13
        R(6, lf, 8, 14, pants)
        R(7, 12, 9, 14 if step != 2 else 13, pants)
        R(6, 15, 9, 15, shoe)


def make_character(name, skin, hair, shirt, pants, pack):
    sheet = Image.new("RGBA", (T * 3, T * 4))
    rows = ["down", "left", "right", "up"]
    for r, direction in enumerate(rows):
        for step in range(3):
            frame = Image.new("RGBA", (T, T))
            src = "left" if direction == "right" else direction
            draw_frame(frame, 0, 0, src, step, skin, hair, shirt, pants, pack)
            if direction == "right":
                frame = frame.transpose(Image.FLIP_LEFT_RIGHT)
            sheet.paste(frame, (step * T, r * T))
    sheet.save(os.path.join(ROOT, "Assets/Characters/%s.png" % name))


CHARS = {
    #            pele               cabelo            camisa            calca            mochila
    "felipe":  (rgb(240, 200, 160), rgb(60, 40, 30),  rgb(220, 160, 40), rgb(50, 70, 120), rgb(110, 72, 42)),
    "manu":    (rgb(200, 150, 110), rgb(30, 24, 24),  rgb(60, 160, 100), rgb(70, 70, 90),  rgb(90, 80, 60)),
    "laura":   (rgb(244, 214, 184), rgb(150, 90, 40), rgb(170, 70, 120), rgb(60, 60, 80),  rgb(120, 90, 60)),
    "eduarda": (rgb(170, 120, 86),  rgb(40, 30, 30),  rgb(70, 130, 210), rgb(240, 240, 240), rgb(60, 70, 100)),
    "tiago":   (rgb(222, 176, 136), rgb(80, 52, 34),  rgb(150, 110, 60), rgb(60, 90, 60),  rgb(90, 64, 40)),
    "lucas":   (rgb(236, 196, 160), rgb(24, 24, 30),  rgb(200, 80, 70),  rgb(50, 50, 60),  rgb(70, 70, 80)),
    # Prof. Proença: cabelo grisalho, jaleco branco
    "proenca": (rgb(226, 184, 146), rgb(206, 206, 212), rgb(246, 246, 250), rgb(70, 74, 96), rgb(150, 150, 160)),
}


# ------------------------------------------------------------- CREATURES
S = 32  # desenhada em 32x32 e ampliada 2x para 64x64 (pixels grandes)


def outline(im, color=(28, 22, 30, 255)):
    src = im.copy()
    px = src.load()
    out = im.load()
    for y in range(im.height):
        for x in range(im.width):
            if px[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < im.width and 0 <= ny < im.height and px[nx, ny][3] > 0:
                        out[x, y] = color
                        break


def save_creature(name, im):
    outline(im)
    im = im.resize((S * 2, S * 2), Image.NEAREST)
    im.save(os.path.join(ROOT, "Assets/Creatures/%s.png" % name))


def new_c():
    im = Image.new("RGBA", (S, S))
    return im, ImageDraw.Draw(im)


def eye(d, x, y):
    d.point((x, y), fill=rgb(250, 250, 250))
    d.point((x, y + 1), fill=rgb(20, 16, 20))


def c_eremotherium():
    im, d = new_c()
    fur, light, claw = rgb(112, 80, 54), rgb(150, 112, 80), rgb(236, 226, 200)
    d.polygon([(24, 14), (31, 20), (30, 24), (23, 22)], fill=fur)       # cauda
    d.ellipse([8, 7, 26, 24], fill=fur)                                   # corpo
    d.ellipse([10, 9, 22, 18], fill=light)
    d.rectangle([20, 20, 25, 28], fill=fur)                               # perna tras.
    d.rectangle([7, 17, 11, 28], fill=fur)                                # braco
    d.rectangle([7, 27, 11, 28], fill=claw)
    d.ellipse([3, 8, 12, 16], fill=light)                                 # cabeca
    d.rectangle([2, 12, 5, 14], fill=fur)
    d.point((2, 13), fill=rgb(30, 20, 20))
    eye(d, 6, 10)
    save_creature("eremotherium", im)


def c_smilodon():
    im, d = new_c()
    fur, dark, fang = rgb(206, 160, 92), rgb(150, 108, 56), rgb(250, 250, 244)
    d.polygon([(25, 12), (31, 11), (31, 14), (25, 16)], fill=fur)         # cauda curta
    d.ellipse([8, 12, 27, 23], fill=fur)
    for x in (13, 16, 19, 22):
        d.line([(x, 12), (x - 1, 17)], fill=dark)
    for x in (9, 14, 20, 24):                                             # patas
        d.rectangle([x, 20, x + 2, 28], fill=fur)
    d.ellipse([2, 8, 12, 18], fill=fur)
    d.polygon([(4, 8), (5, 5), (7, 8)], fill=fur)                         # orelha
    d.polygon([(4, 16), (5, 16), (4, 23)], fill=fang)                     # presa
    d.polygon([(8, 16), (9, 16), (8, 22)], fill=fang)
    eye(d, 5, 11)
    save_creature("smilodon", im)


def c_notiomastodon():
    im, d = new_c()
    hide, dark, tusk = rgb(126, 118, 112), rgb(92, 86, 84), rgb(240, 232, 204)
    d.ellipse([9, 5, 29, 24], fill=hide)
    d.ellipse([11, 6, 24, 13], fill=rgb(148, 140, 132))
    for x in (11, 15, 21, 25):                                            # patas grossas
        d.rectangle([x, 20, x + 3, 28], fill=dark if x in (15, 21) else hide)
    d.ellipse([4, 6, 14, 17], fill=hide)
    d.polygon([(5, 14), (2, 18), (2, 25), (5, 25), (5, 18), (7, 15)], fill=hide)  # tromba
    d.polygon([(5, 17), (2, 19), (3, 21)], fill=tusk)                     # presas
    d.polygon([(3, 21), (1, 24), (4, 23)], fill=tusk)
    d.polygon([(9, 8), (12, 7), (11, 13)], fill=dark)                     # orelha
    eye(d, 7, 9)
    d.polygon([(28, 14), (31, 20), (29, 21)], fill=dark)                  # cauda
    save_creature("notiomastodon", im)


def c_toxodon():
    im, d = new_c()
    hide, dark = rgb(138, 110, 92), rgb(100, 78, 66)
    d.ellipse([7, 10, 28, 24], fill=hide)
    d.ellipse([9, 11, 22, 17], fill=rgb(162, 132, 112))
    for x in (9, 13, 21, 25):
        d.rectangle([x, 21, x + 2, 28], fill=dark if x in (13, 21) else hide)
    d.ellipse([1, 12, 12, 22], fill=hide)                                 # cabeca larga
    d.rectangle([1, 16, 4, 21], fill=dark)                                # focinho
    d.polygon([(6, 12), (7, 9), (9, 12)], fill=dark)                      # orelha
    eye(d, 6, 14)
    d.line([(27, 14), (30, 18)], fill=dark)
    save_creature("toxodon", im)


def c_xenorhinotherium():
    im, d = new_c()
    hide, light = rgb(176, 142, 100), rgb(204, 174, 132)
    d.ellipse([11, 12, 27, 23], fill=hide)
    d.ellipse([13, 13, 24, 18], fill=light)
    for x in (12, 15, 22, 25):                                            # patas longas
        d.rectangle([x, 21, x + 1, 29], fill=hide)
    d.polygon([(11, 14), (7, 6), (11, 4), (14, 12)], fill=hide)           # pescoco
    d.ellipse([3, 2, 12, 8], fill=hide)                                   # cabeca
    d.polygon([(4, 4), (0, 6), (1, 9), (5, 7)], fill=light)               # focinho/probosc.
    d.point((1, 8), fill=rgb(40, 24, 20))
    eye(d, 7, 3)
    d.line([(26, 14), (30, 17)], fill=hide)
    save_creature("xenorhinotherium", im)


def c_glyptodon():
    im, d = new_c()
    shell, dark, skin = rgb(140, 108, 74), rgb(96, 70, 48), rgb(176, 150, 116)
    d.ellipse([5, 5, 28, 23], fill=shell)
    for (cx, cy) in [(11, 11), (16, 9), (21, 11), (13, 16), (19, 16), (9, 17), (24, 17)]:
        d.polygon([(cx, cy - 2), (cx + 2, cy - 1), (cx + 2, cy + 1),
                   (cx, cy + 2), (cx - 2, cy + 1), (cx - 2, cy - 1)], outline=dark)
    d.polygon([(27, 16), (31, 19), (31, 23), (26, 22)], fill=shell)       # cauda
    for x in (9, 13, 20, 24):
        d.rectangle([x, 21, x + 2, 28], fill=skin)
    d.ellipse([1, 15, 9, 23], fill=skin)                                  # cabeca
    d.rectangle([1, 19, 3, 21], fill=dark)
    eye(d, 5, 17)
    save_creature("glyptodon", im)


CREATURES = [c_eremotherium, c_smilodon, c_notiomastodon, c_toxodon,
             c_xenorhinotherium, c_glyptodon]


if __name__ == "__main__":
    make_tileset()
    for n, args in CHARS.items():
        make_character(n, *args)
    for fn in CREATURES:
        fn()
    print("Arte gerada em Assets/.")
