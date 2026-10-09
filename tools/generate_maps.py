#!/usr/bin/env python3
"""Gera Data/maps.json (mapas em tiles + NPCs + portais + encontros).
Legenda: . grama | g capim alto (encontros) | = trilha | T arvore | ~ agua
W parede | R telhado | D porta | f piso | m maquina | x tapete de saida
P portal | S placa | r pedra | L parede do laboratorio
Uso: python3 tools/generate_maps.py"""
import json, os, random
from collections import deque

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rnd = random.Random(2026)


def grid(w, h, ch):
    return [[ch] * w for _ in range(h)]


def border(g, ch="T"):
    h, w = len(g), len(g[0])
    for x in range(w):
        g[0][x] = g[h - 1][x] = ch
    for y in range(h):
        g[y][0] = g[y][w - 1] = ch


def rows(g):
    return ["".join(r) for r in g]


BLOCK = set("T~WRmSrL")


def make_lab():
    g = grid(15, 10, "f")
    for x in range(15):
        g[0][x] = "L"
        g[9][x] = "L"
    for y in range(10):
        g[y][0] = g[y][14] = "L"
    g[9][7] = "x"
    for x in (2, 3, 4, 10, 11, 12):
        g[1][x] = "m"
    for x in (6, 7, 8):
        g[4][x] = "m"
    return {
        "name": "LABORATÓRIO TEMPORAL",
        "tiles": rows(g),
        "warps": [{"x": 7, "y": 9, "to": "base", "tx": 8, "ty": 7, "dir": "down"}],
        "npcs": [
            {"id": "eduarda", "name": "Eduarda", "x": 7, "y": 2, "sprite": "eduarda", "facing": "down",
             "lines": [
                 "Eu cuido da tecnologia da equipe. A TEMPORAL CAPSULE cria um campo seguro em volta da criatura.",
                 "Ela não machuca ninguém: a criatura é estudada por alguns instantes e depois devolvida ao seu tempo.",
                 "O portal para o BRASIL PRÉ-HISTÓRICO fica a leste, depois da porta do laboratório. Boa expedição!"],
             "repeat_lines": ["Em cada encontro você leva 3 cápsulas. Use com cuidado!"]},
            {"id": "manu", "name": "Manu", "x": 3, "y": 5, "sprite": "manu", "facing": "right",
             "lines": [
                 "Eu sou da Biologia. Use ESCANEAR primeiro: ele mostra o habitat e a alimentação da espécie.",
                 "Quanto mais dados você tiver, mais forte fica o sinal de rastreio."],
             "repeat_lines": ["Dica da Biologia: sempre escaneie antes de lançar uma cápsula."]},
            {"id": "laura", "name": "Laura", "x": 11, "y": 5, "sprite": "laura", "facing": "left",
             "lines": [
                 "Eu cuido da parte histórica. No Pleistoceno, o Brasil era casa de preguiças gigantes, tigres-dentes-de-sabre e muito mais.",
                 "A maior parte dessa megafauna desapareceu no fim da última era glacial, há cerca de 11 mil anos.",
                 "A ECODEX só revela a Curiosidade e a História de uma espécie depois que você a estuda de perto."],
             "repeat_lines": ["Registre todas as espécies. Cada uma conta um pedaço da história do Brasil."]},
            # Prof. Proença: o World.gd trata esta conversa de forma especial (ECOMAX + missões)
            {"id": "proenca", "name": "Prof. Proença", "x": 7, "y": 6, "sprite": "proenca", "facing": "down",
             "lines": ["Fale comigo!"]},
            # Felipe vira NPC quando o jogador escolhe outro caçador (o NPC do caçador escolhido é removido)
            {"id": "felipe", "name": "Felipe", "x": 11, "y": 2, "sprite": "felipe", "facing": "down",
             "lines": [
                 "Eu sou o Felipe, líder da equipe. Cuido para que todo mundo volte inteiro de cada expedição.",
                 "Antes de viajar no tempo, fale com o Prof. Proença: ele tem um equipamento novo para a expedição."],
             "repeat_lines": ["Boa sorte lá no Pleistoceno! Estaremos na base esperando por você."]},
        ],
    }


def make_base():
    w, h = 30, 20
    g = grid(w, h, ".")
    border(g)
    for x in range(5, 12):                       # laboratorio (por fora)
        for y in (3, 4):
            g[y][x] = "R"
        for y in (5, 6):
            g[y][x] = "W"
    g[6][8] = "D"
    for y in range(7, 11):                       # trilhas
        g[y][8] = "="
    for x in range(8, 25):
        g[10][x] = "="
    for y in range(9, 12):                       # portal cercado por pedras
        g[y][26] = "r"
    g[9][25] = "r"
    g[11][25] = "r"
    g[10][25] = "P"
    for y in range(13, 17):                      # laguinho
        for x in range(2, 7):
            g[y][x] = "~"
    g[8][9] = "S"                                # placa
    keep = {(x, y) for x in range(4, 13) for y in range(2, 12)}
    keep |= {(x, 10) for x in range(8, 27)}
    for _ in range(70):
        x, y = rnd.randrange(1, w - 1), rnd.randrange(1, h - 1)
        if g[y][x] == "." and (x, y) not in keep and abs(y - 10) > 1:
            g[y][x] = "T"
    return {
        "name": "BASE TEMPORAL",
        "tiles": rows(g),
        "warps": [
            {"x": 8, "y": 6, "to": "lab", "tx": 7, "ty": 8, "dir": "up"},
            {"x": 25, "y": 10, "to": "pleistoceno", "tx": 3, "ty": 10, "dir": "right"},
        ],
        "npcs": [
            {"id": "placa_base", "name": "Placa", "x": 9, "y": 8, "sprite": "",
             "lines": ["BASE TEMPORAL. Portal para o BRASIL PRÉ-HISTÓRICO (Pleistoceno): siga a trilha para leste."]},
            {"id": "tiago", "name": "Tiago", "x": 18, "y": 9, "sprite": "tiago", "facing": "down",
             "lines": [
                 "Meu trabalho é o rastreamento. Capim alto esconde pegadas: ande por ele e algo vai aparecer.",
                 "Use RASTREAR para deixar o sinal mais forte antes de lançar a cápsula."],
             "repeat_lines": ["Rastro fresco no capim alto, do outro lado do portal!"]},
            {"id": "lucas", "name": "Lucas", "x": 13, "y": 11, "sprite": "lucas", "facing": "up",
             "lines": [
                 "Eu planejo a estratégia da equipe. Regra de ouro: não gaste todas as cápsulas de uma vez.",
                 "O sinal temporal dura poucos turnos em cada encontro. Rastreie com planejamento."],
             "repeat_lines": ["Planejamento é tudo: escaneie, rastreie e só então lance a cápsula."]},
        ],
    }


def make_pleistoceno():
    w, h = 30, 20
    g = grid(w, h, ".")
    border(g)
    # lagos
    def ellipse(cx, cy, rx, ry, ch):
        for y in range(h):
            for x in range(w):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    g[y][x] = ch
    ellipse(22, 5, 5, 3, "~")
    ellipse(9, 16, 4, 2, "~")
    # capim alto em manchas
    for _ in range(11):
        cx, cy = rnd.randrange(5, w - 3), rnd.randrange(2, h - 2)
        rx, ry = rnd.uniform(2.2, 4.5), rnd.uniform(1.8, 3.2)
        for y in range(h):
            for x in range(w):
                if g[y][x] == "." and ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    g[y][x] = "g"
    # arvores
    for _ in range(60):
        x, y = rnd.randrange(1, w - 1), rnd.randrange(1, h - 1)
        if g[y][x] in ".g" and not (x <= 8 and 8 <= y <= 12):
            g[y][x] = "T"
    # entrada: portal, pedras e trilha
    for y in (9, 10, 11):
        g[y][1] = "r"
    g[9][2] = "r"
    g[11][2] = "r"
    g[10][2] = "P"
    for x in range(3, 9):
        g[10][x] = "="
    g[9][4] = "S"
    # tudo que for andavel e inalcancavel vira arvore
    seen = set()
    q = deque([(3, 10)])
    seen.add((3, 10))
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and g[ny][nx] not in BLOCK:
                seen.add((nx, ny))
                q.append((nx, ny))
    for y in range(h):
        for x in range(w):
            if g[y][x] not in BLOCK and (x, y) not in seen and g[y][x] != "P":
                g[y][x] = "T"
    ng = sum(r.count("g") for r in g)
    print("pleistoceno: %d tiles de capim alto" % ng)
    return {
        "name": "BRASIL PRÉ-HISTÓRICO - PLEISTOCENO",
        "tiles": rows(g),
        "encounter_color": "#78a85a",
        "encounters": [
            {"id": "eremotherium", "peso": 3},
            {"id": "toxodon", "peso": 3},
            {"id": "notiomastodon", "peso": 2},
            {"id": "xenorhinotherium", "peso": 2},
            {"id": "glyptodon", "peso": 2},
            {"id": "smilodon", "peso": 1},
        ],
        "warps": [{"x": 2, "y": 10, "to": "base", "tx": 24, "ty": 10, "dir": "left"}],
        "npcs": [
            {"id": "placa_pleisto", "name": "Placa", "x": 4, "y": 9, "sprite": "",
             "lines": ["PLEISTOCENO. Criaturas se escondem no capim alto. O portal de volta fica a oeste."]},
        ],
    }


maps = {"lab": make_lab(), "base": make_base(), "pleistoceno": make_pleistoceno()}
with open(os.path.join(ROOT, "Data/maps.json"), "w", encoding="utf-8") as f:
    json.dump(maps, f, ensure_ascii=False, indent=1)
print("Data/maps.json gerado.")
