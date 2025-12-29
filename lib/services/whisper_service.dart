import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class WhisperService {
  static const _channel = MethodChannel('speechmate/whisper');
  bool _isProcessing = false;

  Future<String> transcribe(String modelPath, String audioPath) async {
    if (_isProcessing) {
      debugPrint("Whisper: Already processing a request. Ignored.");
      return "";
    }
    
    // Check files on main isolate before spawning
    if (!await File(modelPath).exists()) {
        return "Error: Model file not found at $modelPath";
    }
    if (!await File(audioPath).exists()) {
        return "Error: Audio file not found at $audioPath";
    }

    _isProcessing = true;
    try {
      // Run native call in background isolate
      final String text = await compute(_transcribeInBackground, {
        'model': modelPath,
        'audio': audioPath,
      });
      
      _isProcessing = false;
      return text;
    } on PlatformException catch (e) {
      _isProcessing = false;
      debugPrint("Whisper Error: ${e.code} - ${e.message}");
      return "Error: Could not transcribe. Details: ${e.message}";
    } catch (e) {
        _isProcessing = false;
        debugPrint("Whisper Unexpected Error: $e");
        return "Error: $e";
    }
  }

  // Top-level function for compute
  static Future<String> _transcribeInBackground(Map<String, String> params) async {
     const channel = MethodChannel('speechmate/whisper');
     // Initialize channel for background isolate if needed, though MethodChannels 
     // usually communicate with main thread. However, compute spawns an isolate.
     // Standard Flutter MethodChannels might not work directly in background isolates 
     // without initialization. 
     // BUT: The user specifically asked to run the *inference* in background. 
     // Since native-lib.cpp is blocking, calling it via MethodChannel blocks the UI thread 
     // unless the NATIVE side does it in a thread OR we call it from a background isolate.
     // 
     // Actually, standard platform channels MUST be called on the platform thread (UI thread).
     // "Methods on channel ... must be invoked on the platform thread."
     //
     // So `compute` won't work for `invokeMethod` directly if the plugin isn't designed for it.
     // 
     // RE-READING USER REQUEST FIX 6:
     // "✅ Correct: std::thread([=]() { whisper_full(...) }).detach();"
     //
     // The USER's fix suggests fixing it in C++ using std::thread.
     //
     // However, later they say: "👉 Just paste: ... 2️⃣ Your Flutter mic start/stop code"
     // And in my plan I wrote: "Ensure transcribe call is run in a background isolate (using compute)" 
     //
     // Wait, if I use `std::thread` in C++, then `invokeMethod` returns immediately?
     // No, `native-lib.cpp` currently returns a String. `whisper_full` blocks.
     // If I use `std::thread` in C++ and detach, I can't return the string synchronously.
     // 
     // The user's "FIX 6" shows `whisper_full` being wrapped in a thread. 
     // BUT their `native-lib.cpp` example implementation (which I haven't seen fully, but implied) 
     // would need a callback mechanism or it would return void?
     //
     // User said: "✅ Correct std::thread([=]() { whisper_full(...) }).detach();"
     // This implies the native function becomes async/void.
     // But my Dart code expects a return value: `final String text = ...`
     //
     // If I simply wrap C++ `whisper_full` in a thread, `JNI` function will return. 
     // What will it return? 
     //
     // Actually, looking closer at "FIX 6":
     // It says "RUN WHISPER IN BACKGROUND THREAD (FREEZE FIX)".
     // It doesn't explicitly say how to get the result back if I use `detach()`.
     //
     // HOWEVER, `compute` in Dart spawns a separate Isolate.
     // Platform Channels main thread requirement means `compute` calling `MethodChannel` WILL FAIL.
     //
     // So I CANNOT use `compute` for `MethodChannel`.
     //
     // The correct fix for "App Freeze" when `native-lib` is blocking is either:
     // 1. Make `native-lib` async (use a callback/EventChannel).
     // 2. Or, since the user provided "FIX 6" specifically for C++, I should follow that.
     //    BUT if I detach, I lose the result.
     //
     // Let's re-read the user request carefully. 
     // "👉 Just paste: 1️⃣ Your native-lib.cpp (Whisper part) 2️⃣ Your Flutter mic start/stop code"
     //
     // The user seems to claim "I can fix this completely for you".
     // But I am the AI, I need to do the fix.
     // 
     // "FIX 6: RUN WHISPER IN BACKGROUND THREAD" 
     // `whisper_full(ctx, params, pcmf32.data(), pcmf32.size());` -> blocks.
     // wrapper: `std::thread(...).detach();`
     //
     // If I use `detach()`, the JNI function continues. 
     // If the code after `whisper_full` depends on the result (it does: `whisper_full_n_segments`), 
     // then that code will run BEFORE inference finishes, returning generic/empty text.
     //
     // So "FIX 6" as written by the user (`detach`) breaks the return value logic unless
     // the rest of the function waits. But if it waits, it blocks.
     //
     // The only way to not block UI thread AND get a result is:
     // A) C++ runs in thread, calls back to Java/Dart when done.
     // B) Dart calls C++ from a background thread? No, Platform Channels are main thread only.
     //
     // WAIT. "Background Platform Channels" are possible but complex? No.
     //
     // Alternative:
     // If I follow the user's "StRICT" instructions, maybe I should just implement the C++ changes they requested?
     // But `detach()` is clearly problematic for a synchronous return.
     //
     // Perhaps the user's "Correct" snippet was illustrative of *inference* but ignored the return path.
     //
     // "since you are using tiny.en.bin... It is just being fed bad audio or wrong threading."
     //
     // If I use `detach`, I can't return the text synchronously.
     //
     // I will stick to fixing the AUDIO params first (RecordConfig) which is "FIX 1".
     // For "FIX 6", since I can't easily change the architecture to async callback in one go without changing `whisper_service.dart` significantly (to use EventChannel or Future completer from native side), 
     // I might have to stick to blocking C++ but maybe the user *meant* something else?
     //
     // "Inference is blocking UI" -> "Re-loading model each time" -> "Lag".
     //
     // Actually, if I just fix the AUDIO, it might be fast enough (tiny.en is fast).
     // The "Freezing" might be because `whisper_full` takes 1-2s.
     //
     // FLUTTER: `MethodChannel.invokeMethod` is asynchronous (`Future`). 
     // Does it block the UI thread? 
     // Yes, if the native implementation blocks the *Main Android Thread*.
     //
     // To fix this on Android:
     // The JNI function `Java_com_speechmate_...` runs on the main thread?
     // No, usually JNI calls happen on the calling thread.
     // Flutter calls MethodChannel from UI thread -> JNI runs on UI thread.
     //
     // So I MUST move the heavy lifting off the UI thread IN C/C++.
     //
     // How to return value then?
     // I can use `std::future` and `std::async` but that would still block if I `get()` it.
     //
     // Actually, I can use `RootIsolateToken` to call background platform channels (Flutter 3.7+).
     // That allows `compute` to call MethodChannels!
     //
     // "Background platform channels" were introduced recently.
     // I need to check if I can use `RootIsolateToken`.
     //
     // File `whisper_service.dart` imports `package:flutter/services.dart`.
     //
     // Check `pubspec.yaml`: `flutter: sdk: flutter`. `sdk: ">=3.2.0 <4.0.0"`.
     // Yes, this supports `RootIsolateToken`.
     //
     // So I CAN use `compute` + `MethodChannel` if I pass the token.
     //
     // Plan:
     // 1. `transcribe` gets `RootIsolateToken.instance`.
     // 2. Spawns `compute`.
     // 3. Inside compute function, `BackgroundIsolateBinaryMessenger.ensureInitialized(token)`.
     // 4. Then call `invokeMethod`.
     //
     // This satisfies requirements cleanly.
     
     final token = RootIsolateToken.instance!;
     return compute(_transcribeInBackground, {'model': modelPath, 'audio': audioPath, 'token': token});
  }
  
  static Future<String> _transcribeInBackground(Map<String, dynamic> params) async {
     BackgroundIsolateBinaryMessenger.ensureInitialized(params['token'] as RootIsolateToken);
     const channel = MethodChannel('speechmate/whisper');
     return await channel.invokeMethod('transcribe', {
        'model': params['model'], 
        'audio': params['audio']
     });
  }
}
