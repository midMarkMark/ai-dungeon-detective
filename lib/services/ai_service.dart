import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';

/// A service to interact with QuillBot AI Chat headlessly via direct API fetch.
/// This is the AI brain for AI Dungeon Detective.
class QuillBotService {
  late final WebViewController _controller;
  Completer<String>? _responseCompleter;
  bool _isPageLoaded = false;
  bool _isInitialized = false;
  bool _isProcessing = false;

  QuillBotService() {
    // Defer initialization until explicitly called or accessed
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('[QuillBotService] Initializing WebViewController...');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // Use a mobile User Agent to mimic a real device
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[QuillBotService] Page started loading: $url');
            _isPageLoaded = false;
          },
          onPageFinished: (url) {
            debugPrint('[QuillBotService] Page finished loading: $url');
            _isPageLoaded = true;
            _enableLightMode();
          },
          onWebResourceError: (error) {
            debugPrint('[QuillBotService] Web resource error: ${error.description}');
          },
          onNavigationRequest: (req) {
            if (req.url.contains('quillbot.com')) return NavigationDecision.navigate;
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'ApiListener',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message.startsWith('STATUS:')) {
            debugPrint('[QuillBotService JS Log] ${message.message}');
            return;
          }

          if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
            _responseCompleter!.complete(message.message);
            _responseCompleter = null;
          }
        },
      );

    _controller.loadRequest(Uri.parse('https://quillbot.com/ai-chat'));
    _isInitialized = true;
  }

  /// The WebView widget that must be mounted somewhere in the widget tree (e.g. Offstage)
  Widget get webView {
    if (!_isInitialized) {
      initialize();
    }
    return WebViewWidget(controller: _controller);
  }

  /// Replaces the heavy website UI with a lightweight placeholder
  Future<void> _enableLightMode() async {
    const js = '''
      (function() {
        document.body.innerHTML = `
          <div style="display: flex; justify-content: center; align-items: center; height: 100vh; background: #f0f0f0;">
            <h1 style="color: #333;">⚡ QuillBot Service Active</h1>
          </div>
        `;
      })();
    ''';
    await _controller.runJavaScript(js);
  }

  void dispose() {
    if (!_isInitialized) return;
    debugPrint('[QuillBotService] Disposing service...');
    _controller.loadRequest(Uri.parse('about:blank'));
    _controller.clearCache();
    _isInitialized = false;
    _isPageLoaded = false;
  }

  /// Core method: Send a prompt to QuillBot AI and get the response
  /// This is the main method the game will use for all AI interactions
  Future<String> sendPrompt(String prompt) async {
    if (!_isInitialized) await initialize();

    // Wait for page to load
    int retries = 0;
    while (!_isPageLoaded) {
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
      if (retries > 30) {
        throw Exception('QuillBot page load timeout');
      }
    }

    if (_isProcessing) {
      throw Exception('AI is already processing a request');
    }

    _isProcessing = true;
    _responseCompleter = Completer<String>();

    try {
      final safeText = jsonEncode(prompt);

      final jsCode = '''
      (async function() {
          try {
              const inputMessage = $safeText;
              const payload = {
                  "stream": true,
                  "message": {
                      "role": "user",
                      "content": inputMessage,
                      "messageId": Math.random().toString(36).substring(2, 15),
                      "createdAt": new Date().toISOString(),
                      "files": []
                  },
                  "product": "ai-chat",
                  "originUrl": "/ai-chat",
                  "prompt": { "id": "ai_chat" },
                  "tools": []
              };

              window.ApiListener.postMessage("STATUS: Sending Request...");

              const response = await fetch('https://quillbot.com/api/raven/quill-chat/responses', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json', 'Accept': '*/*' },
                  body: JSON.stringify(payload)
              });

              if (!response.ok) {
                  window.ApiListener.postMessage("Error: " + response.status);
                  return;
              }

              const reader = response.body.getReader();
              const decoder = new TextDecoder();
              let fullText = '';

              while (true) {
                  const { done, value } = await reader.read();
                  if (done) break;

                  fullText += decoder.decode(value, { stream: true });

                  if (fullText.includes('"status":"DONE"')) {
                     const outputMarker = 'event: output_done';
                     const outputIndex = fullText.lastIndexOf(outputMarker);

                     if (outputIndex !== -1) {
                         const dataMarker = 'data: ';
                         const dataIndex = fullText.indexOf(dataMarker, outputIndex);

                         if (dataIndex !== -1) {
                             let endIndex = fullText.indexOf('\\n\\n', dataIndex);
                             if (endIndex === -1) endIndex = fullText.length;

                             const jsonString = fullText.substring(dataIndex + dataMarker.length, endIndex).trim();
                             try {
                                 const parsed = JSON.parse(jsonString);
                                 if (parsed.text) {
                                     window.ApiListener.postMessage(parsed.text);
                                     return;
                                 }
                             } catch (e) { console.error("Parse error", e); }
                         }
                     }
                  }
              }
              window.ApiListener.postMessage("Error: Stream ended without valid JSON");
          } catch (err) {
              window.ApiListener.postMessage("JS Error: " + err.toString());
          }
      })();
      ''';

      await _controller.runJavaScript(jsCode);
      final response = await _responseCompleter!.future.timeout(const Duration(seconds: 60));
      return response;
    } catch (e) {
      debugPrint('[QuillBotService] Request Error: $e');
      rethrow;
    } finally {
      _isProcessing = false;
    }
  }

  /// Send a prompt and parse the response as JSON
  Future<Map<String, dynamic>?> sendPromptJson(String prompt) async {
    try {
      final rawResponse = await sendPrompt(prompt);
      return _cleanAndParseJsonMap(rawResponse);
    } catch (e) {
      debugPrint('[QuillBotService] JSON Request Error: $e');
      return null;
    }
  }

  /// Send a prompt and parse the response as a JSON list
  Future<List<dynamic>?> sendPromptJsonList(String prompt) async {
    try {
      final rawResponse = await sendPrompt(prompt);
      final result = _cleanAndParseJson(rawResponse);
      return (result is List) ? result : null;
    } catch (e) {
      debugPrint('[QuillBotService] JSON List Request Error: $e');
      return null;
    }
  }

  dynamic _cleanAndParseJson(String raw) {
    try {
      String clean = raw.trim();
      final RegExp jsonRegex = RegExp(r'(\[[\\s\\S]*\]|\{[\\s\\S]*\})');
      final match = jsonRegex.firstMatch(clean);

      if (match != null) {
        clean = match.group(0)!;
        return jsonDecode(clean);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? _cleanAndParseJsonMap(String raw) {
    final result = _cleanAndParseJson(raw);
    return (result is Map<String, dynamic>) ? result : null;
  }
}