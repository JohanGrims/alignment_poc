import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'test_cases.dart';
// Note: This relies on flutter_rust_bridge_codegen to generate the 'src/rust/' bindings.
// You will need to run: `flutter_rust_bridge_codegen generate`
import 'src/rust/api/alignment.dart' as rust;
import 'src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const AlignmentPoCApp());
}

class AlignmentPoCApp extends StatelessWidget {
  const AlignmentPoCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vecalign PoC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      home: const AlignmentPlayground(),
    );
  }
}

class SegmentData {
  final rust.AlignmentPair sentenceAlignment;
  final String sourceText;
  final String targetText;
  final List<RegExpMatch> sourceWords;
  final List<RegExpMatch> targetWords;
  final List<rust.AlignmentPair> wordAlignments;
  
  SegmentData(this.sentenceAlignment, this.sourceText, this.targetText, this.sourceWords, this.targetWords, this.wordAlignments);
}

class AlignmentPlayground extends StatefulWidget {
  const AlignmentPlayground({super.key});

  @override
  State<AlignmentPlayground> createState() => _AlignmentPlaygroundState();
}

class _AlignmentPlaygroundState extends State<AlignmentPlayground> {
  final _sourceController = TextEditingController();
  final _targetController = TextEditingController();

  TestCase? _selectedTest;
  bool _isLoading = false;
  List<SegmentData> _segments = [];
  int _alignmentDurationMs = 0;
  String _error = "";
  double? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _loadTestCase(predefinedTests.first);
    _loadModel();
  }

  void _loadTestCase(TestCase testCase) {
    setState(() {
      _selectedTest = testCase;
      _sourceController.text = testCase.source;
      _targetController.text = testCase.target;
      _segments = [];
      _error = "";
    });
  }

  Future<void> _downloadFile(String url, String savePath) async {
    final file = File(savePath);
    if (await file.exists()) return;

    setState(() {
      _error = "Downloading ${path.basename(savePath)}...";
      _downloadProgress = 0.0;
    });

    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode == 200) {
      final contentLength = response.contentLength;
      int downloaded = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (contentLength != null) {
          setState(() {
            _downloadProgress = downloaded / contentLength;
          });
        }
      }
      await sink.close();
    } else {
      throw Exception("Failed to download file from $url: ${response.statusCode}");
    }
    
    setState(() {
      _downloadProgress = null;
    });
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final onnxPath = path.join(docDir.path, "model_quantized.onnx");
      final tokenizerPath = path.join(docDir.path, "tokenizer.json");

      const onnxUrl = "https://huggingface.co/Xenova/paraphrase-multilingual-MiniLM-L12-v2/resolve/main/onnx/model_quantized.onnx";
      const tokenizerUrl = "https://huggingface.co/Xenova/paraphrase-multilingual-MiniLM-L12-v2/resolve/main/tokenizer.json";

      await _downloadFile(onnxUrl, onnxPath);
      await _downloadFile(tokenizerUrl, tokenizerPath);

      setState(() => _error = "Initializing ONNX model in Rust...");
      await rust.loadModel(
        onnxPath: onnxPath,
        tokenizerPath: tokenizerPath
      );
      setState(() => _error = "Model loaded successfully.");
    } catch (e) {
      setState(() => _error = "Error loading model: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAndReloadModel() async {
    setState(() => _isLoading = true);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final onnxFile = File(path.join(docDir.path, "model_quantized.onnx"));
      final tokenizerFile = File(path.join(docDir.path, "tokenizer.json"));

      if (await onnxFile.exists()) await onnxFile.delete();
      if (await tokenizerFile.exists()) await tokenizerFile.delete();

      final stopwatch = Stopwatch()..start();
      
      const onnxUrl = "https://huggingface.co/Xenova/paraphrase-multilingual-MiniLM-L12-v2/resolve/main/onnx/model_quantized.onnx";
      const tokenizerUrl = "https://huggingface.co/Xenova/paraphrase-multilingual-MiniLM-L12-v2/resolve/main/tokenizer.json";

      await _downloadFile(onnxUrl, onnxFile.path);
      await _downloadFile(tokenizerUrl, tokenizerFile.path);
      
      final downloadTime = stopwatch.elapsedMilliseconds;
      stopwatch.reset();
      
      setState(() => _error = "Initializing ONNX model in Rust...");
      await rust.loadModel(
        onnxPath: onnxFile.path,
        tokenizerPath: tokenizerFile.path
      );
      final loadTime = stopwatch.elapsedMilliseconds;
      
      setState(() {
        _error = "Model deleted, re-downloaded (${downloadTime}ms) and loaded into RAM (${loadTime}ms).";
      });
    } catch (e) {
      setState(() => _error = "Error reloading model: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<List<String>> _getParagraphSentences(String text) {
    return text.split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty)
        .map((p) => p.split(RegExp(r'(?<=[.!?])\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList())
        .where((sents) => sents.isNotEmpty).toList();
  }

  List<String> _getSentences(String text) {
    return _getParagraphSentences(text).expand((e) => e).toList();
  }

  Future<void> _exportJson() async {
    if (_segments.isEmpty) return;
    try {
      final List<Map<String, dynamic>> mappings = _segments.map((seg) {
        final a = seg.sentenceAlignment;
        final isPenalty = a.sourceIndices.isEmpty || a.targetIndices.isEmpty;
        final scaleFactor = (a.sourceIndices.length + a.targetIndices.length) / 2.0;
        final conf = isPenalty ? 0.0 : 1.0 - (a.score / scaleFactor);
        return {
          "source_indices": a.sourceIndices,
          "target_indices": a.targetIndices,
          "source_text": seg.sourceText,
          "target_text": seg.targetText,
          "confidence_percent": isPenalty ? null : double.parse((conf * 100).toStringAsFixed(1)),
          "cost": double.parse(a.score.toStringAsFixed(3)),
          "is_penalty": isPenalty,
        };
      }).toList();

      final exportData = {
        "metadata": {
          "total_segments": _segments.length,
          "total_penalties": _segments.where((s) => s.sentenceAlignment.sourceIndices.isEmpty || s.sentenceAlignment.targetIndices.isEmpty).length,
          "duration_ms": _alignmentDurationMs,
          "timestamp": DateTime.now().toIso8601String(),
        },
        "mappings": mappings,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File(path.join(downloadsDir.path, "alignment_export_${DateTime.now().millisecondsSinceEpoch}.json"));
      await file.writeAsString(jsonString);

      setState(() {
        _error = "Exported successfully to: ${file.path}";
      });
    } catch (e) {
      setState(() {
        _error = "Failed to export JSON: $e";
      });
    }
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isLoading = true;
      _error = "Running all evaluation tests...";
    });

    try {
      for (int testIdx = 0; testIdx < predefinedTests.length; testIdx++) {
        var testCase = predefinedTests[testIdx];
        final stopwatch = Stopwatch()..start();
        final result = await _hierarchicalAlign(testCase.source, testCase.target);
        stopwatch.stop();

        final List<Map<String, dynamic>> mappings = result.map((seg) {
          final a = seg.sentenceAlignment;
          final isPenalty = a.sourceIndices.isEmpty || a.targetIndices.isEmpty;
          final scaleFactor = (a.sourceIndices.length + a.targetIndices.length) / 2.0;
          final conf = isPenalty ? 0.0 : 1.0 - (a.score / scaleFactor);

          List<Map<String, dynamic>> wordMappings = [];
          if (!isPenalty) {
            for (final wa in seg.wordAlignments) {
              final wConf = 1.0 - wa.score;
              final sWords = wa.sourceIndices.map((i) => seg.sourceWords[i as int].group(0)!).join(" ");
              final tWords = wa.targetIndices.map((i) => seg.targetWords[i as int].group(0)!).join(" ");
              wordMappings.add({
                "s_words": sWords,
                "t_words": tWords,
                "conf": double.parse((wConf * 100).toStringAsFixed(1)),
              });
            }
          }

          return {
            "type": isPenalty ? "PENALTY" : "${a.sourceIndices.length}:${a.targetIndices.length}",
            "s_txt": seg.sourceText,
            "t_txt": seg.targetText,
            "conf": isPenalty ? null : double.parse((conf * 100).toStringAsFixed(1)),
            "cost": double.parse(a.score.toStringAsFixed(3)),
            "word_alignments": wordMappings,
          };
        }).toList();

        final exportData = {
          "metadata": {
            "test_title": testCase.title,
            "duration_ms": stopwatch.elapsedMilliseconds,
            "total_segments": result.length,
            "penalties": result.where((s) => s.sentenceAlignment.sourceIndices.isEmpty || s.sentenceAlignment.targetIndices.isEmpty).length,
            "timestamp": DateTime.now().toIso8601String(),
          },
          "mappings": mappings,
        };

        final safeTitle = testCase.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
        final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
        final downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File(path.join(downloadsDir.path, 'eval_$safeTitle.json'));
        await file.writeAsString(jsonString);
      }

      setState(() {
        _isLoading = false;
        _error = "Generated separate eval JSON files for ${predefinedTests.length} in your Downloads folder.";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Eval failed: $e";
      });
    }
  }

  Future<List<rust.AlignmentPair>> _runSlidingWindowLogic(List<String> sourceSentences, List<String> targetSentences, {bool clearCacheFirst = true, int maxAlign = 3}) async {
    if (clearCacheFirst) {
      await rust.clearCache();
    }

    List<rust.AlignmentPair> finalAlignments = [];
    int sIdx = 0;
    int tIdx = 0;
    const windowSize = 20;

    while (sIdx < sourceSentences.length || tIdx < targetSentences.length) {
      int sEnd = (sIdx + windowSize < sourceSentences.length) ? sIdx + windowSize : sourceSentences.length;
      int tEnd = (tIdx + windowSize < targetSentences.length) ? tIdx + windowSize : targetSentences.length;

      final srcWindow = sourceSentences.sublist(sIdx, sEnd);
      final tgtWindow = targetSentences.sublist(tIdx, tEnd);

      if (srcWindow.isEmpty && tgtWindow.isNotEmpty) {
        for (int i = tIdx; i < targetSentences.length; i++) {
          finalAlignments.add(rust.AlignmentPair(sourceIndices: Int32List.fromList([]), targetIndices: Int32List.fromList([i]), score: 0.4));
        }
        break;
      } else if (tgtWindow.isEmpty && srcWindow.isNotEmpty) {
        for (int i = sIdx; i < sourceSentences.length; i++) {
          finalAlignments.add(rust.AlignmentPair(sourceIndices: Int32List.fromList([i]), targetIndices: Int32List.fromList([]), score: 0.4));
        }
        break;
      }

      final windowAlignments = await rust.alignSentences(
        sourceSentences: srcWindow,
        targetSentences: tgtWindow,
        maxAlign: maxAlign
      );

      int anchorS = -1;
      int anchorT = -1;
      int commitCount = 0;

      for (int i = 0; i < windowAlignments.length; i++) {
        final a = windowAlignments[i];
        if (a.sourceIndices.isNotEmpty && a.targetIndices.isNotEmpty) {
          final scaleFactor = (a.sourceIndices.length + a.targetIndices.length) / 2.0;
          final conf = 1.0 - (a.score / scaleFactor);
          if (conf >= 0.55 && a.sourceIndices.last < srcWindow.length * 0.75 && a.targetIndices.last < tgtWindow.length * 0.75) {
            anchorS = a.sourceIndices.last;
            anchorT = a.targetIndices.last;
            commitCount = i + 1;
          }
        }
      }

      if (commitCount > 0) {
        for (int i = 0; i < commitCount; i++) {
          final a = windowAlignments[i];
          final mappedA = rust.AlignmentPair(
            sourceIndices: Int32List.fromList(a.sourceIndices.map((x) => x + sIdx).toList()),
            targetIndices: Int32List.fromList(a.targetIndices.map((x) => x + tIdx).toList()),
            score: a.score
          );
          finalAlignments.add(mappedA);
        }
        sIdx += anchorS + 1;
        tIdx += anchorT + 1;
      } else {
        bool hasAnyMatch = windowAlignments.any((a) => a.sourceIndices.isNotEmpty && a.targetIndices.isNotEmpty);
        if (hasAnyMatch) {
          final firstStep = windowAlignments.first;
          final mappedA = rust.AlignmentPair(
            sourceIndices: Int32List.fromList(firstStep.sourceIndices.map((x) => x + sIdx).toList()),
            targetIndices: Int32List.fromList(firstStep.targetIndices.map((x) => x + tIdx).toList()),
            score: firstStep.score
          );
          finalAlignments.add(mappedA);
          sIdx += firstStep.sourceIndices.length;
          tIdx += firstStep.targetIndices.length;
          if (firstStep.sourceIndices.isEmpty && firstStep.targetIndices.isEmpty) sIdx++;
        } else {
          if (srcWindow.length >= tgtWindow.length) {
            finalAlignments.add(rust.AlignmentPair(sourceIndices: Int32List.fromList([sIdx]), targetIndices: Int32List.fromList([]), score: 0.4));
            sIdx++;
          } else {
            finalAlignments.add(rust.AlignmentPair(sourceIndices: Int32List.fromList([]), targetIndices: Int32List.fromList([tIdx]), score: 0.4));
            tIdx++;
          }
        }
      }
    }
    return finalAlignments;
  }

  Future<List<rust.AlignmentPair>> _splitIfPossible(rust.AlignmentPair sa, List<String> srcSents, List<String> tgtSents) async {
    if (sa.sourceIndices.length > 1 && sa.targetIndices.length > 1) {
      final subSrc = sa.sourceIndices.map((idx) => srcSents[idx]).toList();
      final subTgt = sa.targetIndices.map((idx) => tgtSents[idx]).toList();
      final splitAlignments = await _runSlidingWindowLogic(subSrc, subTgt, clearCacheFirst: false, maxAlign: 1);
      bool hasPenalties = splitAlignments.any((a) => a.sourceIndices.isEmpty || a.targetIndices.isEmpty);
      if (!hasPenalties) {
        return splitAlignments.map((splitA) => rust.AlignmentPair(
          sourceIndices: Int32List.fromList(splitA.sourceIndices.map((i) => sa.sourceIndices[i]).toList()),
          targetIndices: Int32List.fromList(splitA.targetIndices.map((i) => sa.targetIndices[i]).toList()),
          score: splitA.score
        )).toList();
      }
    }
    return [sa];
  }

  Future<List<SegmentData>> _hierarchicalAlign(String sourceText, String targetText) async {
    await rust.clearCache();
    final sourceParaSents = _getParagraphSentences(sourceText);
    final targetParaSents = _getParagraphSentences(targetText);
    final sourceParagraphs = sourceParaSents.map((sents) => sents.join(" ")).toList();
    final targetParagraphs = targetParaSents.map((sents) => sents.join(" ")).toList();

    final paraAlignments = await _runSlidingWindowLogic(sourceParagraphs, targetParagraphs, clearCacheFirst: false, maxAlign: 1);
    List<rust.AlignmentPair> finalSentenceAlignments = [];
    int globalSourceSentenceIdx = 0;
    int globalTargetSentenceIdx = 0;

    for (final pa in paraAlignments) {
      List<String> srcSents = [];
      for (int i in pa.sourceIndices) srcSents.addAll(sourceParaSents[i]);
      List<String> tgtSents = [];
      for (int i in pa.targetIndices) tgtSents.addAll(targetParaSents[i]);

      if (srcSents.isEmpty && tgtSents.isEmpty) continue;
      else if (srcSents.isEmpty && tgtSents.isNotEmpty) {
        for (int i = 0; i < tgtSents.length; i++) finalSentenceAlignments.add(rust.AlignmentPair(sourceIndices: Int32List.fromList([]), targetIndices: Int32List.fromList([globalTargetSentenceIdx + i]), score: 0.4));
      } else if (tgtSents.isEmpty && srcSents.isNotEmpty) {
        for (int i = 0; i < srcSents.length; i++) finalSentenceAlignments.add(rust.AlignmentPair(sourceIndices: Int32List.fromList([globalSourceSentenceIdx + i]), targetIndices: Int32List.fromList([]), score: 0.4));
      } else {
        final sentAlignments = await _runSlidingWindowLogic(srcSents, tgtSents, clearCacheFirst: false, maxAlign: 3);
        for (final sa in sentAlignments) {
          final splitAlignments = await _splitIfPossible(sa, srcSents, tgtSents);
          for (final splitSa in splitAlignments) {
            finalSentenceAlignments.add(rust.AlignmentPair(
              sourceIndices: Int32List.fromList(splitSa.sourceIndices.map((idx) => idx + globalSourceSentenceIdx).toList()),
              targetIndices: Int32List.fromList(splitSa.targetIndices.map((idx) => idx + globalTargetSentenceIdx).toList()),
              score: splitSa.score
            ));
          }
        }
      }
      globalSourceSentenceIdx += srcSents.length;
      globalTargetSentenceIdx += tgtSents.length;
    }

    List<SegmentData> segments = [];
    final allSourceSentences = sourceParaSents.expand((e) => e).toList();
    final allTargetSentences = targetParaSents.expand((e) => e).toList();
    final wordRegex = RegExp(r"[\p{L}\p{N}]+", unicode: true);

    for (final sa in finalSentenceAlignments) {
      final sText = sa.sourceIndices.map((i) => allSourceSentences[i]).join(" ");
      final tText = sa.targetIndices.map((i) => allTargetSentences[i]).join(" ");
      final sourceWords = wordRegex.allMatches(sText).toList();
      final targetWords = wordRegex.allMatches(tText).toList();
      
      List<rust.AlignmentPair> wordAlignments = [];
      if (sa.sourceIndices.isNotEmpty && sa.targetIndices.isNotEmpty && sourceWords.isNotEmpty && targetWords.isNotEmpty) {
        final sourceSpans = sourceWords.map((m) => rust.WordSpan(start: m.start, end: m.end, text: m.group(0)!)).toList();
        final targetSpans = targetWords.map((m) => rust.WordSpan(start: m.start, end: m.end, text: m.group(0)!)).toList();
        wordAlignments = await rust.alignWordsContextual(
          sourceText: sText,
          sourceSpans: sourceSpans,
          targetText: tText,
          targetSpans: targetSpans,
          threshold: 0.3,
        );
      }
      segments.add(SegmentData(sa, sText, tText, sourceWords, targetWords, wordAlignments));
    }
    return segments;
  }

  Future<void> _alignSlidingWindow() async {
    setState(() {
      _isLoading = true;
      _error = "";
      _segments = [];
    });
    try {
      final sw = Stopwatch()..start();
      final segments = await _hierarchicalAlign(_sourceController.text, _targetController.text);
      sw.stop();
      setState(() {
        _segments = segments;
        _alignmentDurationMs = sw.elapsedMilliseconds;
      });
    } catch (e) {
      setState(() => _error = "Sliding Window Alignment failed: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildRichText(String text, List<RegExpMatch> words, List<RegExpMatch> oppositeWords, List<rust.AlignmentPair> wordAlignments, bool isSource, bool isPenalty) {
    if (isPenalty) {
      return Text(text.isEmpty ? "[OMITTED]" : text, style: TextStyle(color: text.isEmpty ? Colors.grey : Colors.black87));
    }
    
    final List<Color> palette = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.blueGrey,
      Colors.redAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.deepPurpleAccent,
      Colors.indigoAccent, Colors.blueAccent, Colors.lightBlueAccent, Colors.cyanAccent,
      Colors.tealAccent, Colors.greenAccent, Colors.lightGreenAccent, Colors.limeAccent,
      Colors.yellowAccent, Colors.amberAccent, Colors.orangeAccent, Colors.deepOrangeAccent,
    ];

    List<InlineSpan> spans = [];
    int lastPos = 0;
    
    for (int i = 0; i < words.length; i++) {
      final match = words[i];
      if (match.start > lastPos) {
        spans.add(TextSpan(text: text.substring(lastPos, match.start), style: const TextStyle(color: Colors.black87)));
      }
      
      final alignmentIndex = wordAlignments.indexWhere((a) => isSource ? a.sourceIndices.contains(i) : a.targetIndices.contains(i));
      
      if (alignmentIndex != -1) {
        final a = wordAlignments[alignmentIndex];
        final conf = (1.0 - a.score).clamp(0.0, 1.0);
        final baseColor = palette[alignmentIndex % palette.length];
        // Mix base color with white to create a pastel look, varying by confidence
        final bgColor = Color.lerp(Colors.white, baseColor, 0.3 + (conf * 0.5))!;
        
        final mappedIndices = isSource ? a.targetIndices : a.sourceIndices;
        final mappedWords = mappedIndices.map((idx) => oppositeWords[idx as int].group(0)!).join(" ");
        final tooltipMsg = "Match: $mappedWords\nConf: ${(conf * 100).toStringAsFixed(1)}%";

        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Tooltip(
            message: tooltipMsg,
            waitDuration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(match.group(0)!, style: const TextStyle(color: Colors.black87)),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: match.group(0), 
          style: const TextStyle(color: Colors.black87, backgroundColor: Colors.white)
        ));
      }
      lastPos = match.end;
    }
    
    if (lastPos < text.length) {
      spans.add(TextSpan(text: text.substring(lastPos), style: const TextStyle(color: Colors.black87)));
    }
    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildSegmentList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_segments.isEmpty) return const Center(child: Text("Click 'Align' to see results"));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _segments.length,
      itemBuilder: (context, index) {
        final seg = _segments[index];
        final sa = seg.sentenceAlignment;
        bool isPenalty = sa.sourceIndices.isEmpty || sa.targetIndices.isEmpty;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildRichText(seg.sourceText, seg.sourceWords, seg.targetWords, seg.wordAlignments, true, isPenalty)),
                Expanded(flex: 2, child: Column(children: [Text("${sa.sourceIndices.length}:${sa.targetIndices.length}", style: const TextStyle(fontWeight: FontWeight.bold)), Text("Cost: ${sa.score.toStringAsFixed(2)}", style: const TextStyle(fontSize: 10))])),
                Expanded(flex: 5, child: _buildRichText(seg.targetText, seg.targetWords, seg.sourceWords, seg.wordAlignments, false, isPenalty)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vecalign Playground (MiniLM-L12)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete & Reload Model',
            onPressed: _isLoading ? null : _deleteAndReloadModel,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Select Test Case: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<TestCase>(
                    isExpanded: true,
                    value: _selectedTest,
                    items: predefinedTests.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.title),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _loadTestCase(val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: _error.contains("Error") ? Colors.red.shade100 : Colors.green.shade100,
                width: double.infinity,
                child: Column(
                  children: [
                    Text(_error),
                    if (_downloadProgress != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _downloadProgress),
                    ]
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sourceController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        labelText: 'Original (English)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        labelText: 'Translation (German)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: _isLoading ? null : _alignSlidingWindow,
                  icon: const Icon(Icons.waves),
                  label: const Text('Align (Sliding Window)'),
                ),
                const SizedBox(width: 16),
                FilledButton.tonalIcon(
                  onPressed: _isLoading || _segments.isEmpty ? null : _exportJson,
                  icon: const Icon(Icons.download),
                  label: const Text('Export JSON'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: _isLoading ? null : _runAllTests,
                  icon: const Icon(Icons.science),
                  label: const Text('Run All Tests (Eval)'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _segments.isEmpty
                  ? const Center(child: Text("Click 'Align Sentences' to see the result."))
                  : Column(
                      children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("$_alignmentDurationMs ms", style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 16),
                            const Icon(Icons.analytics, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("${_segments.length} segments", style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 16),
                            const Icon(Icons.warning_amber, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "${_segments.where((a) => a.sentenceAlignment.sourceIndices.isEmpty || a.sentenceAlignment.targetIndices.isEmpty).length} penalties",
                              style: const TextStyle(color: Colors.grey)
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentList(),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
