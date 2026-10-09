# Como colocar o jogo no ar (GitHub Pages)

Você NÃO precisa instalar o Godot nem exportar nada. O GitHub faz isso sozinho.

1. Crie uma conta em github.com e clique em **New repository** (nome sugerido: `extinct-brasil`, deixe **Public**).
2. Suba TODO o conteúdo desta pasta para o repositório (inclusive a pasta `.github`).
   - Mais fácil: instale o **GitHub Desktop**, adicione a pasta e faça *Commit* + *Publish*.
   - Se usar o site (Add file > Upload files), confira depois se a pasta `.github/workflows` apareceu.
     Se não apareceu, use *Add file > Create new file*, digite o nome `.github/workflows/publicar.yml`
     e cole o conteúdo do arquivo `publicar.yml` que acompanha este projeto.
3. No repositório: **Settings > Pages > Build and deployment > Source = GitHub Actions**.
4. Abra a aba **Actions**. Aguarde o fluxo "Publicar jogo no GitHub Pages" ficar verde (uns 3 a 6 minutos).
   Se não começou sozinho: clique no fluxo e em **Run workflow**.
5. O link do jogo é `https://SEU-USUARIO.github.io/extinct-brasil/` (aparece também em Settings > Pages).

Toda vez que você mudar algo e enviar para o GitHub, o jogo é atualizado sozinho.
No celular: abra o link e use o menu do navegador > **Adicionar à tela inicial**.
