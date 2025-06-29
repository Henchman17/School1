import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;

class DownloadRequestSlip extends StatefulWidget {
  const DownloadRequestSlip({super.key});

  @override
  State<DownloadRequestSlip> createState() => _DownloadRequestSlipState();
}

class _DownloadRequestSlipState extends State<DownloadRequestSlip> {
  bool _isDownloading = false;
  String _statusMessage = '';

  Future<void> _downloadAndOpenPDF() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Download Confirmation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text('Do you want to download the Request Slip PDF?'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Download'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) {
      setState(() {
        _statusMessage = 'Download cancelled.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Preparing download...';
    });

    try {
      final pdfData = await rootBundle.load('assets/files/Request Slip.pdf');

      if (kIsWeb) {
        final blob = html.Blob([pdfData.buffer.asUint8List()], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..download = 'Request Slip.pdf'
          ..style.display = 'none';
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
        setState(() {
          _statusMessage = 'Download started in browser.';
        });
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/Request Slip.pdf');
        await file.writeAsBytes(pdfData.buffer.asUint8List());
        setState(() {
          _statusMessage = 'File saved to ${file.path}';
        });
        await OpenFile.open(file.path);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error during download: $e';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Request Slip'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
      ),
      body: Center(
        child: _isDownloading
            ? const CircularProgressIndicator()
            : Text(
                _statusMessage.isEmpty ? 'Ready to download.' : _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}
