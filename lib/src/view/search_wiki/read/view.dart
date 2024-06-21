import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ninja_scrolls/extentions.dart';
import 'package:ninja_scrolls/src/gateway/wiki.dart';
import 'package:ninja_scrolls/src/providers/scaffold_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as windows;

class SearchWikiReadViewArgument {
  final String wikiEndpoint;
  final String wikiTitle;
  const SearchWikiReadViewArgument(
      {this.key, required this.wikiEndpoint, required this.wikiTitle});

  final Key? key;
}

class SearchWikiReadView extends StatefulWidget {
  final SearchWikiReadViewArgument argument;
  const SearchWikiReadView({super.key, required this.argument});

  @override
  State<SearchWikiReadView> createState() => _SearchWikiReadViewState();
}

class NavigatorAvailability {
  final bool canGoBack;
  final bool canGoForward;
  const NavigatorAvailability(this.canGoBack, this.canGoForward);
}

class _SearchWikiReadViewState extends State<SearchWikiReadView> {
  WebViewController? webViewController;
  late final windows.WebviewController windowsWebviewController =
      windows.WebviewController();
  bool isInitialLoading = true;

  late final String initialUrl =
      WikiNetworkGateway.getUrl(widget.argument.wikiEndpoint);
  late String _currentUrl = initialUrl;
  NavigatorAvailability navigatorAvailability =
      NavigatorAvailability(false, false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      context.read<ScaffoldProvider>().wikiTitle = widget.argument.wikiTitle;
    });

    if (Platform.isWindows) {
      initializeWindows();
    } else {
      webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {
              Future.wait([
                webViewController!.canGoBack(),
                webViewController!.canGoForward(),
              ]).then((values) {
                if (!mounted) return;
                setState(() {
                  navigatorAvailability =
                      NavigatorAvailability(values[0], values[1]);
                });
              });
            },
            onPageFinished: (String url) {
              if (isInitialLoading && mounted) {
                setState(() {
                  isInitialLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {},
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(
            Uri.parse(WikiNetworkGateway.getUrl(widget.argument.wikiEndpoint)));
    }
  }

  Future initializeWindows() async {
    await windowsWebviewController.initialize();
    await Future.wait([
      windowsWebviewController.setBackgroundColor(Colors.white),
      windowsWebviewController
          .setPopupWindowPolicy(windows.WebviewPopupWindowPolicy.deny),
    ]);

    await windowsWebviewController.loadUrl(initialUrl);
    if (mounted) setState(() {});
    windowsWebviewController.url.listen((event) {
      _currentUrl = event;
    });
    windowsWebviewController.historyChanged.listen((state) {
      setState(() {
        isInitialLoading = false;
        navigatorAvailability =
            NavigatorAvailability(state.canGoBack, state.canGoForward);
      });
    });

    windowsWebviewController.loadUrl(initialUrl);
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowsWebviewController.dispose();
    }
    super.dispose();
  }

  Widget get webviewBottomBar {
    // back, forward, reload, open in browser, copy link
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.colorTheme.primary
                .withOpacity(navigatorAvailability.canGoBack ? 1 : 0.3),
          ),
          onPressed: () async {
            if (Platform.isWindows) {
              await windowsWebviewController.goBack();
            } else {
              await webViewController!.goBack();
            }
          },
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            color: context.colorTheme.primary
                .withOpacity(navigatorAvailability.canGoForward ? 1 : 0.3),
          ),
          onPressed: () async {
            if (Platform.isWindows) {
              await windowsWebviewController.goForward();
            } else {
              await webViewController!.goForward();
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: context.colorTheme.primary),
          onPressed: () async {
            if (Platform.isWindows) {
              await windowsWebviewController.reload();
            } else {
              await webViewController!.reload();
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.open_in_browser, color: context.colorTheme.primary),
          onPressed: () async {
            final url = await currentUrl;
            if (url == null) return;
            if (await canLaunchUrlString(url)) {
              launchUrlString(url);
            }
          },
        ),
        IconButton(
          icon: Icon(Icons.link, color: context.colorTheme.primary),
          onPressed: () async {
            final url = await currentUrl;
            if (url == null) return;
            final data = ClipboardData(text: url);
            await Clipboard.setData(data);
          },
        ),
      ],
    );
  }

  Future<String?> get currentUrl async {
    if (Platform.isWindows) {
      return _currentUrl;
    } else {
      return await webViewController!.currentUrl();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: isInitialLoading
                ? Center(child: CircularProgressIndicator.adaptive())
                : Platform.isWindows
                    ? windows.Webview(windowsWebviewController)
                    : WebViewWidget(controller: webViewController!),
          ),
          webviewBottomBar,
        ],
      ),
    );
  }
}
