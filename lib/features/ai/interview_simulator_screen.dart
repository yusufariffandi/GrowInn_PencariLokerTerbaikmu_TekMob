import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_colors.dart';
import '../../services/gemini_service.dart';
import '../../shared/widgets/glass_widgets.dart';

enum _InputMode { text, voice }

class _ChatMsg {
  final String role; // 'ai' | 'user'
  final String text;
  _ChatMsg(this.role, this.text);
}

/// Latihan Wawancara AI — simulasi wawancara kerja lewat chat dengan AI
/// yang berperan sebagai HRD profesional (ditenagai Google Gemini).
/// Kandidat bisa menjawab dengan mengetik ATAU dengan suara (speech-to-text),
/// sedangkan AI selalu membalas dalam bentuk teks (boleh memakai emote).
class InterviewSimulatorScreen extends StatefulWidget {
  final String? jobTitle;
  const InterviewSimulatorScreen({super.key, this.jobTitle});

  @override
  State<InterviewSimulatorScreen> createState() => _InterviewSimulatorScreenState();
}

class _InterviewSimulatorScreenState extends State<InterviewSimulatorScreen> {
  late String _jobTitle = (widget.jobTitle == null || widget.jobTitle!.trim().isEmpty)
      ? 'Umum / Belum ditentukan'
      : widget.jobTitle!.trim();

  final List<_ChatMsg> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _loadingAi = true;
  String? _error;
  bool _finished = false;

  _InputMode _mode = _InputMode.text;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  String _liveTranscript = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _requestAiTurn();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _listening = false);
          }
        },
        onError: (err) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Minta balasan HRD (AI) berikutnya berdasarkan seluruh transkrip
  /// percakapan sejauh ini.
  Future<void> _requestAiTurn() async {
    setState(() {
      _loadingAi = true;
      _error = null;
    });
    try {
      final reply = await GeminiService.instance.interviewReply(
        jobTitle: _jobTitle,
        history: _messages.map((m) => {'role': m.role, 'text': m.text}).toList(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMsg('ai', reply));
        if (reply.contains('HASIL EVALUASI WAWANCARA')) _finished = true;
      });
      _scrollToBottom();
    } on GeminiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Gagal terhubung ke AI: $e');
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  Future<void> _sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loadingAi || _finished) return;
    setState(() {
      _messages.add(_ChatMsg('user', trimmed));
      _controller.clear();
      _liveTranscript = '';
    });
    _scrollToBottom();
    await _requestAiTurn();
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      setState(() => _error =
          'Mikrofon tidak tersedia / izin ditolak. Coba pakai mode ketik, atau izinkan akses mikrofon di pengaturan.');
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _liveTranscript = '';
      _listening = true;
      _error = null;
    });
    await _speech.listen(
      localeId: 'id_ID',
      onResult: (result) {
        setState(() => _liveTranscript = result.recognizedWords);
      },
    );
  }

  void _restart() {
    setState(() {
      _messages.clear();
      _finished = false;
      _error = null;
      _liveTranscript = '';
    });
    _requestAiTurn();
  }

  Future<void> _editJobTitle() async {
    final controller = TextEditingController(text: _jobTitle);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Posisi yang dilamar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Contoh: Frontend Developer'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => c.pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () => c.pop(controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != _jobTitle) {
      setState(() => _jobTitle = result);
      _restart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          shape: const CircleBorder()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Latihan Wawancara AI',
                              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                          Text('Posisi: $_jobTitle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editJobTitle,
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      tooltip: 'Ganti posisi',
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          shape: const CircleBorder()),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _restart,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      tooltip: 'Mulai ulang',
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.5),
                          shape: const CircleBorder()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  itemCount: _messages.length + (_loadingAi ? 1 : 0),
                  itemBuilder: (c, i) {
                    if (i >= _messages.length) {
                      return _typingBubble();
                    }
                    final m = _messages[i];
                    return _bubble(m);
                  },
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: GlassPane(
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(fontSize: 12, color: AppColors.error))),
                      ],
                    ),
                  ),
                ),
              if (_finished)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: PrimaryPillButton(
                    label: 'Latihan Lagi dari Awal',
                    icon: Icons.replay_rounded,
                    onPressed: _restart,
                  ),
                )
              else
                _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const SizedBox(
          width: 28,
          height: 14,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(_ChatMsg m) {
    final isAi = m.role == 'ai';
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAi ? Colors.white.withValues(alpha: 0.65) : AppColors.black,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAi)
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text('HRD GrowIn 🤝',
                    style: TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              ),
            Text(
              m.text,
              style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isAi ? AppColors.textPrimary : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _modeChip(_InputMode.text, Icons.keyboard_rounded, 'Ketik'),
              const SizedBox(width: 8),
              _modeChip(_InputMode.voice, Icons.mic_rounded, 'Suara'),
            ],
          ),
          const SizedBox(height: 8),
          _mode == _InputMode.text ? _textInputRow() : _voiceInputRow(),
        ],
      ),
    );
  }

  Widget _modeChip(_InputMode mode, IconData icon, String label) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () {
        if (_listening) _speech.stop();
        setState(() {
          _mode = mode;
          _listening = false;
        });
      },
      child: GlassChip(label: label, icon: icon, filled: selected),
    );
  }

  Widget _textInputRow() {
    return GlassPane(
      borderRadius: 9999,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_loadingAi,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendText,
              decoration: const InputDecoration(
                hintText: 'Tulis jawabanmu...',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadingAi ? null : () => _sendText(_controller.text),
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
                backgroundColor: AppColors.black, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _voiceInputRow() {
    return GlassPane(
      borderRadius: 22,
      child: Column(
        children: [
          Text(
            _liveTranscript.isEmpty
                ? (_listening ? 'Mendengarkan... silakan bicara 🎙️' : 'Tekan tombol mic untuk mulai bicara')
                : _liveTranscript,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _loadingAi ? null : _toggleListening,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? AppColors.error : AppColors.black,
                    boxShadow: _listening
                        ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.35), blurRadius: 16)]
                        : null,
                  ),
                  child: Icon(_listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white, size: 26),
                ),
              ),
              if (_liveTranscript.isNotEmpty && !_listening) ...[
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () => setState(() => _liveTranscript = ''),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Hapus',
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadingAi ? null : () => _sendText(_liveTranscript),
                  icon: const Icon(Icons.send_rounded),
                  tooltip: 'Kirim',
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.black, foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
