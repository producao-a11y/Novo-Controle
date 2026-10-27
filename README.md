# Controle de Reuniões — Flutter para Android

Aplicativo Flutter que reproduz a interface e as regras **do HTML fornecido** em uma WebView Android. O HTML/CSS/JavaScript original está incluído em `assets/reunioes.html` e roda localmente, sem servidor. Não é uma reimplementação de widgets nativos Flutter: a camada Flutter hospeda a interface e integra cópia, exportação e tela ligada.

## Compilar usando somente o GitHub

1. Crie um repositório **vazio** no GitHub (sem README ou .gitignore inicial).
2. Extraia este ZIP e envie **o conteúdo da pasta** para a raiz do repositório, incluindo `.github/workflows/android-apk.yml` (a pasta `.github` é oculta em alguns gerenciadores).
3. Abra a aba **Actions** no GitHub e selecione **Compilar APK Android**. Caso não inicie automaticamente, clique em **Run workflow**.
4. Aguarde a conclusão e abra a execução. Em **Artifacts**, baixe `controle-reunioes-apk`.
5. Extraia o arquivo baixado e instale `app-release.apk` no Android. O APK gerado pelo workflow usa a assinatura de debug/release padrão do Flutter; para publicação na Play Store, configure assinatura própria.

O workflow executa `flutter create` para gerar os arquivos padrão Android, depois `flutter build apk --release`. Não é necessário subir arquivos Android gerados para o repositório.

## Compilar localmente

Instale Flutter e Android SDK e execute:

```bash
flutter create --platforms=android --project-name controle_reunioes --org br.com.controle --no-pub .
flutter pub get
flutter build apk --release
```

APK em `build/app/outputs/flutter-apk/app-release.apk`.

## Dados e limitações

- Reuniões ficam no `localStorage` do WebView, no armazenamento privado do aplicativo.
- Desinstalar o app ou limpar os dados apaga os registros. Exporte o resumo/CSV antes.
- A contagem usa relógio real, mesmo em segundo plano; a tela ligada é solicitada quando a reunião começa.
- A exportação CSV abre a folha de compartilhamento do Android para salvar/enviar o arquivo.
- Fontes Google podem precisar de internet; há fontes substitutas.
- Não há migração automática dos dados salvos no navegador onde o HTML era utilizado.
- O projeto não foi compilado/testado em dispositivo neste ambiente, pois Flutter SDK não está instalado aqui.
