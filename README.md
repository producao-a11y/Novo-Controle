# Controle de Reuniões — Projeto Flutter Android

Aplicativo Android que apresenta a interface HTML local em uma WebView Flutter. A interface, as regras de negócio e o armazenamento local são implementados em `assets/reunioes.html`; `lib/main.dart` hospeda a WebView e integra recursos nativos.

## Estrutura do projeto

- `lib/main.dart`: inicialização Flutter, criação da WebView, tratamento de mensagens do JavaScript e estados de carregamento/erro.
- `assets/reunioes.html`: interface HTML/CSS/JavaScript e funcionalidades do aplicativo.
- `pubspec.yaml`: dependências Flutter e declaração do HTML como recurso empacotado.
- `.github/workflows/android-apk.yml`: automação de compilação do APK no GitHub Actions.

As funções JavaScript e métodos Dart têm comentários de documentação próximos às declarações para explicar seus papéis. Ao alterar a interface, mantenha o HTML da raiz sincronizado com `assets/reunioes.html` caso ambos sejam mantidos separadamente.

## Compilar pelo GitHub

1. Crie um repositório vazio no GitHub.
2. Extraia este ZIP e envie o conteúdo da pasta do projeto para a raiz do repositório, incluindo `.github/workflows/android-apk.yml`.
3. Abra **Actions** e selecione **Compilar APK Android**. Se necessário, use **Run workflow**.
4. Após a conclusão, abra a execução e baixe o artefato `controle-reunioes-apk`.
5. Extraia o artefato e instale `app-release.apk` no dispositivo Android.

O workflow cria os arquivos de plataforma Android com Flutter e executa `flutter build apk --release`.

## Compilar localmente

Com Flutter e Android SDK instalados, execute na raiz do projeto:

```bash
flutter create --platforms=android --project-name controle_reunioes --org br.com.controle --no-pub .
flutter pub get
flutter build apk --release
```

O APK será gerado em `build/app/outputs/flutter-apk/app-release.apk`.

## Integração entre HTML e Flutter

O HTML envia mensagens JSON pelo canal JavaScript `NativeApp`. O método `_onMessage` em `lib/main.dart` trata estas ações:

- `wake`: mantém a tela ligada durante o cronômetro.
- `sleep`: desativa o bloqueio de repouso da tela.
- `copy`: copia texto para a área de transferência.
- `csv`: cria um CSV temporário e abre a folha de compartilhamento do Android.

Se uma ação nova for adicionada no HTML, inclua o tratamento correspondente na ponte nativa.

## Armazenamento e dados

- Os registros são mantidos no `localStorage` da WebView, dentro do armazenamento privado do aplicativo.
- Desinstalar o aplicativo ou limpar seus dados remove os registros locais.
- A interface utiliza o relógio real para contabilizar a reunião mesmo quando o aplicativo está em segundo plano.
- Exporte backups antes de reinstalar ou limpar dados do aplicativo.
- O HTML é carregado localmente; fontes externas podem depender de conexão, mas não são necessárias para carregar a tela.

## Verificação

O projeto precisa ser compilado pelo GitHub Actions ou em ambiente com Flutter instalado para validar a geração do APK.
