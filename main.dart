import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Inicializa o Flutter e inicia a aplicação Controle de Reuniões.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeetingApp());
}

/// Define a configuração global, o tema e a tela inicial do aplicativo.
class MeetingApp extends StatelessWidget {
  const MeetingApp({super.key});
  /// Constrói a estrutura raiz do aplicativo Flutter.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Controle de Reuniões',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: const MeetingScreen(),
      );
}

/// Cria a tela que hospeda a interface HTML dentro de uma WebView.
class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});
  /// Cria o estado responsável pelo ciclo de vida da WebView.
  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

/// Gerencia a WebView, a ponte JavaScript-nativa e os estados de carregamento.
class _MeetingScreenState extends State<MeetingScreen> {
  WebViewController? controller;
  bool ready = false;
  String? error;

  /// Dispara a configuração da interface web após a criação do estado.
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Prepara o HTML no armazenamento privado e configura a WebView local.
  Future<void> _initialize() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final webDir = Directory('${dir.path}/web');
      await webDir.create(recursive: true);
      final htmlFile = File('${webDir.path}/index.html');
      // Preserve the same file:// origin between launches for localStorage.
      await htmlFile.writeAsString(await rootBundle.loadString('assets/reunioes.html'));
      final webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xffF2F4F6))
        ..addJavaScriptChannel('NativeApp', onMessageReceived: _onMessage)
        ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
          if (mounted) setState(() => ready = true);
        }))
        ..loadFile(htmlFile.path);
      controller = webController;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  /// Processa ações solicitadas pelo HTML através do canal NativeApp.
  /// Ações aceitas: manter a tela ligada, desligar o wakelock, copiar texto e compartilhar CSV.
  Future<void> _onMessage(JavaScriptMessage message) async {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      switch (data['action']) {
        // Mantém a tela acesa enquanto o cronômetro da reunião está ativo.
        case 'wake':
          await WakelockPlus.enable();
          break;
        // Permite que a tela volte ao comportamento normal de repouso.
        case 'sleep':
          await WakelockPlus.disable();
          break;
        // Copia o texto solicitado pela interface web para a área de transferência.
        case 'copy':
          await Clipboard.setData(ClipboardData(text: data['text'] as String));
          break;
        // Gera um arquivo temporário CSV e abre o compartilhamento do Android.
        case 'csv':
          final dir = await getTemporaryDirectory();
          final name = (data['filename'] as String).replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          final file = File('${dir.path}/$name');
          await file.writeAsString(data['text'] as String, flush: true);
          await Share.shareXFiles([XFile(file.path)], text: 'Exportação do Controle de Reuniões');
          break;
      }
    } catch (e) {
      debugPrint('Native bridge error: $e');
    }
  }

  /// Libera o wakelock quando a tela Flutter é descartada.
  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  /// Exibe a WebView ou os estados de carregamento e erro.
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: error != null
              ? Center(child: Text('Falha ao abrir o aplicativo: $error'))
              : controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : !ready
                      ? Stack(children: [WebViewWidget(controller: controller!), const Center(child: CircularProgressIndicator())])
                      : WebViewWidget(controller: controller!),
        ),
      );
}
