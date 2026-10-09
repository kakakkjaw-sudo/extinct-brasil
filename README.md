# EXTINCT: BRASIL - The Time Hunters

Jogo 2D top-down de exploração e coleção de criaturas extintas do Brasil.
Explorar -> Encontrar -> Rastrear -> Capturar -> Registrar -> Completar a ECODEX.

## Como abrir e jogar
1. Baixe o **Godot 4.2 ou mais novo** (versão "Standard", NÃO a ".NET") em https://godotengine.org/download
   O Godot não precisa de instalação: é só descompactar e abrir.
2. Abra o Godot, clique em **Importar**, escolha o arquivo `project.godot` desta pasta.
3. Aguarde a importação dos arquivos e aperte **F5** (ou o botão de play).

## Controles
| Tecla | Ação |
|---|---|
| Setas ou WASD | Andar |
| Z, Enter, Espaço ou E | Interagir / avançar texto / escolher no menu |
| X ou Esc | Voltar / fechar |
| C ou I | Abrir a ECODEX (precisa do ECOMAX) |
| M ou Q | Abrir a lista de MISSÕES (precisa do ECOMAX) |
| F9 | Reiniciar a ECODEX e as missões (modo de teste) |
| F10 | Liga/desliga os controles de toque na tela (para testar no PC) |

### No celular (toque)
| Toque | Ação |
|---|---|
| Direcional (esquerda da tela) | Andar (pode deslizar o dedo de uma seta para outra) |
| Botão **A** | Interagir / avançar texto / escolher |
| Botão **B** | Voltar / fechar |
| **ECODEX** e **MISSÕES** (canto superior direito) | Abrem o ECOMAX (precisa pegar com o Prof. Proença) |
| Tocar em qualquer lugar da tela | Avança diálogos e textos dos encontros |
| Tocar nos botões ESCANEAR / RASTREAR / CÁPSULA / RECUAR | Escolhe a ação no encontro |
| Tocar nas opções da tela inicial e nos caçadores | Seleciona (toque de novo no caçador para confirmar) |

Os controles aparecem sozinhos em aparelhos com tela de toque e usam vários dedos ao mesmo tempo
(andar com um dedo e apertar A com outro). O jogo é horizontal: se o celular estiver em pé, aparece
um aviso para girar.

## Jogar no celular
O jogo é o mesmo projeto: não existe uma versão separada. Há dois caminhos:

**1) Pelo navegador do celular (mais fácil, e funciona no GitHub Pages)**
1. No Godot (use a **4.3 ou mais nova**: a exportação Web dela não exige os cabeçalhos especiais
   que o GitHub Pages não oferece), baixe os *export templates*: menu **Editor > Gerenciar Modelos de Exportação**.
2. **Projeto > Exportar > Adicionar... > Web**. Em *Exclude Filter* escreva `_referencia_original/*, tools/*`.
3. Em *Export Path* escolha `docs/index.html` (o nome precisa ser `index.html`) e clique em **Exportar Projeto**.
4. Crie o arquivo vazio `docs/.nojekyll` (evita que o GitHub Pages ignore arquivos do jogo).
5. Suba a pasta para o GitHub. Em **Settings > Pages**, escolha *Deploy from a branch*, branch `main`, pasta `/docs`.
6. Abra o link no celular. No Chrome: menu **⋮ > Adicionar à tela inicial** (no iPhone: Compartilhar > Adicionar à Tela de Início).
   O salvamento fica guardado no navegador do aparelho.

**2) Aplicativo Android (.apk)**
**Projeto > Exportar > Adicionar... > Android** (precisa do JDK e do Android SDK; o Godot pede os
caminhos em *Editor > Configurações do Editor > Exportar > Android*). Depois conecte o celular com
depuração USB e use **Implantação com um clique** (ícone do Android no topo do Godot).

**Testar os controles de toque no PC:** aperte **F10** (liga a tela de toque). Para o mouse funcionar como
dedo, ative em *Configurações do Projeto > Dispositivos de Entrada > Pointing > Emulate Touch From Mouse*
(só para testar; desligue depois).

## Como jogar (versão atual)
1. **Tela inicial**: NOVO JOGO, CONTINUAR (carrega o último salvamento) ou OPÇÕES (controles).
2. **Escolha seu caçador**: setas para escolher, Z para selecionar e Z de novo para confirmar.
   Cada caçador tem uma habilidade nos encontros (veja `Data/equipe.json`).
3. Você começa no **Laboratório Temporal**. Fale com o **Prof. Proença**: ele entrega o **ECOMAX**
   (ECODEX + lista de missões) e explica a primeira missão. Sem o ECOMAX o portal fica desligado.
4. Cumpra as missões (`Data/missoes.json`) e volte ao Prof. Proença para receber a próxima.
   O jogo avisa na tela quando uma missão é cumprida e algumas dão cápsulas extras.
5. No **Brasil Pré-Histórico (Pleistoceno)**, ande no capim alto para encontrar criaturas.
6. No encontro: **ESCANEAR** (mostra habitat e alimentação), **RASTREAR** (aumenta o sinal),
   **CÁPSULA** (Temporal Capsule: quanto maior o sinal, maior a chance) ou **RECUAR**.
7. Espécies vistas ficam registradas; espécies capturadas liberam Curiosidade e História na ECODEX.
O jogo salva sozinho (personagem, ECOMAX, missões, posição) ao trocar de mapa, depois de encontros e de falar com o Prof. Proença.

## Caçadores e habilidades
| Caçador | Função | Habilidade |
|---|---|---|
| Lucas | Estratégia | +1 cápsula em cada encontro |
| Eduarda | Tecnologia | cápsulas 10% mais eficientes |
| Manu | Biologia | ESCANEAR rende +10 de sinal extra |
| Tiago | Rastreamento | RASTREAR rende +8 de sinal |
| Felipe | Liderança | +1 de tempo em cada encontro |
| (reservado) | - | vaga bloqueada (Laura), `"jogavel": false` |

O caçador escolhido não aparece como NPC; os outros ficam no laboratório e na base.

## Como trocar as fotos dos caçadores
Coloque a imagem em `Assets/Portraits/<id>.png` (id = lucas, eduarda, manu, tiago, felipe), com o
mesmo nome do arquivo atual. Qualquer tamanho serve; a proporção ideal é 3:5 (ex.: 300x500).
Para liberar a vaga reservada: ponha `Assets/Portraits/laura.png` e troque `"jogavel": false` por `true`
em `Data/equipe.json` (e acrescente um `bonus`, se quiser).

## Como adicionar uma missão
Acrescente um bloco ao final de `Data/missoes.json`. Tipos: `visit` (campo `alvo` = id do mapa),
`seen` (descobrir `meta` espécies) e `captured` (estudar `meta` espécies; `0` = todas).
Campos: `titulo`, `descricao`, `recompensa` (falas do Prof. Proença) e `capsulas` (extra opcional).

## Estrutura
- `World/` mapa em tiles, jogador, NPCs, portais, encontros, conversa do Prof. Proença
- `UI/` tela inicial, escolha de caçador, diálogo, encontro/captura, ECODEX, missões
- `Scripts/` autoloads (`Game`: controles e salvamento; `Ecodex`: dados e progresso; `Quests`: missões;
  `TouchControls`: direcional e botões na tela para celular)
- `Data/` `species.json` (Ecodex), `maps.json` (mapas), `equipe.json` (caçadores), `missoes.json` (missões)
- `tools/` geradores de arte e mapas (Python + Pillow)
- `_referencia_original/` código original da base MonsterCollector (ignorado pelo Godot)

## Como adicionar uma espécie
1. Adicione um bloco em `Data/species.json` (copie um existente, use um `numero` novo).
2. Coloque o sprite 64x64 em `Assets/Creatures/`.
3. Inclua o `id` na lista `encounters` do mapa desejado em `Data/maps.json`.

## Créditos
- Base de código inicial: projeto MonsterCollector (protótipo Godot 4). Os assets dele (sprites
  derivados de Pokémon, instaladores .exe e música) foram removidos.
- Toda a arte atual é provisória e gerada por código (`tools/generate_art.py`). Nenhum asset de terceiros.
- Os textos científicos são resumos escolares: confira e cite as fontes que seu professor exigir.
- A arte da tela inicial e os retratos vêm das imagens enviadas pelo autor (`Assets/UI`, `Assets/Portraits`).
- Os 6 personagens são fictícios; as funções são invenção do jogo.
