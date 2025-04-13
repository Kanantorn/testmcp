import 'dart:convert';
import 'dart:async';
import 'dart:io';

/// A simple direct runner for the MCP Sequential Thinking server
/// This class provides a method to send a request directly to an MCP Sequential Thinking server
/// that is already running and accessible via stdio
class DirectMCPRunner {
  /// Send a prompt to the MCP Sequential Thinking server and receive the response
  static Future<Map<String, dynamic>> sendPrompt(String prompt) async {
    // Connect to stdin and stdout
    final stdin = io.stdin;
    final stdout = io.stdout;
    
    // Buffer for storing output
    StringBuffer outputBuffer = StringBuffer();
    Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
    
    // Send the prompt to the server
    print('\nSending prompt to MCP server:');
    print('--------------------------');
    print(prompt);
    print('--------------------------\n');
    
    // Send the prompt to the MCP server
    stdout.write(prompt + '\n');
    
    // Start listening for server response
    StreamSubscription? subscription;
    subscription = stdin.transform(utf8.decoder).listen((data) {
      print('Received data from MCP server: $data');
      outputBuffer.write(data);
      
      try {
        // Try to parse the response as JSON
        final responseJson = json.decode(outputBuffer.toString());
        
        if (!completer.isCompleted) {
          completer.complete(responseJson);
          subscription?.cancel();
        }
      } catch (e) {
        // JSON parsing failed, continue collecting more data
        print('Not a valid JSON response yet, continuing to collect data');
      }
    });
    
    // Set a timeout
    Timer(const Duration(seconds: 120), () {
      if (!completer.isCompleted) {
        completer.completeError('Timeout waiting for MCP server response');
        subscription?.cancel();
      }
    });
    
    return completer.future;
  }
} 