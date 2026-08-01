import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Semua fitur AI di GrowIn (CV Generator, Cover Letter,
/// Salary Insight) memanggil satu service ini, yang membungkus Google Gemini
/// REST API (Generative Language API).
///
/// Setup:
/// 1. Buka https://aistudio.google.com/app/apikey
/// 2. Buat API key (gratis, cukup akun Google)
/// 3. Isi GEMINI_API_KEY di file .env
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _model => dotenv.env['GEMINI_MODEL'] ?? 'gemini-3.5-flash';

  Uri get _endpoint => Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');

  bool get isConfigured => _apiKey.isNotEmpty && _apiKey != 'your-gemini-api-key';

  Future<String> _generate({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxOutputTokens = 1024,
    int thinkingBudget = 0,
  }) async {
    if (!isConfigured) {
      throw GeminiException(
          'GEMINI_API_KEY belum diatur. Tambahkan API key di file .env (lihat .env.example).');
    }

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        'topP': 0.9,
        // PENTING: model gemini-3.5-flash (dan varian "thinking" lainnya) diam-diam
        // memakai sebagian besar maxOutputTokens untuk proses "berpikir" internal
        // sebelum menulis jawaban akhir. Kalau tidak dibatasi, jawaban yang benar-benar
        // ditampilkan/dibacakan sering kepotong di tengah kalimat karena token sudah
        // habis duluan untuk reasoning yang tidak pernah ditampilkan. Untuk fitur
        // jawaban singkat, budget ini di-nolkan
        // supaya semua token dipakai untuk jawaban yang benar-benar keluar & lebih cepat.
        'thinkingConfig': {'thinkingBudget': thinkingBudget},
      },
    });

    final res = await http
        .post(_endpoint, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      // Sebagian model lama tidak mengenal field thinkingConfig — kalau itu
      // penyebab errornya, otomatis coba ulang tanpa field tersebut daripada
      // langsung menggagalkan seluruh sesi wawancara.
      if (res.statusCode == 400 && res.body.contains('thinkingConfig')) {
        return _generateWithoutThinkingConfig(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
        );
      }
      throw GeminiException('Gemini API error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('Gemini tidak mengembalikan respons. Coba lagi.');
    }
    final finishReason = candidates[0]['finishReason'] as String?;
    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw GeminiException('Respons Gemini kosong.');
    }
    final text = (parts[0]['text'] as String).trim();
    // Kalau Gemini berhenti karena kehabisan token (bukan karena selesai wajar),
    // lebih baik minta ulang dengan budget lebih besar daripada membacakan kalimat
    // yang kepotong ke pengguna.
    if (finishReason == 'MAX_TOKENS' && text.isNotEmpty && maxOutputTokens < 2000) {
      return _generate(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        temperature: temperature,
        maxOutputTokens: maxOutputTokens + 400,
        thinkingBudget: thinkingBudget,
      );
    }
    return text;
  }

  /// Fallback untuk model yang tidak mengenal field `thinkingConfig` sama
  /// sekali (mis. model non-"thinking" lama) — dipanggil otomatis saat API
  /// menolak field tersebut, memakai [maxOutputTokens] yang lebih besar
  /// sebagai gantinya supaya jawaban tetap tidak kepotong.
  Future<String> _generateWithoutThinkingConfig({
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int maxOutputTokens,
  }) async {
    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        'topP': 0.9,
      },
    });

    final res = await http
        .post(_endpoint, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw GeminiException('Gemini API error ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiException('Gemini tidak mengembalikan respons. Coba lagi.');
    }
    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw GeminiException('Respons Gemini kosong.');
    }
    return (parts[0]['text'] as String).trim();
  }

  // ==================== SALARY INSIGHT ====================
  Future<String> salaryInsight({
    required String position,
    required String location,
    required String experienceLevel,
  }) {
    const systemPrompt = '''
Kamu adalah analis kompensasi & benefit (compensation analyst) di Indonesia.
Berikan estimasi rentang gaji bulanan (dalam Rupiah) yang realistis untuk pasar kerja
Indonesia tahun ini, beserta 2-3 kalimat insight singkat tentang faktor yang mempengaruhi
gaji tersebut. Jawab ringkas, langsung, Bahasa Indonesia, tanpa markdown.''';
    final userPrompt =
        'Posisi: $position\nLokasi: $location\nLevel pengalaman: $experienceLevel\n\nBerikan estimasi gaji dan insight singkat:';
    return _generate(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      maxOutputTokens: 400,
      thinkingBudget: 0,
    );
  }

  // ==================== SIMULASI WAWANCARA KERJA (AI HRD) ====================

  /// System prompt HRD profesional untuk simulasi wawancara kerja berbasis
  /// chat. Kandidat boleh menjawab lewat teks maupun suara (hasil
  /// speech-to-text dikirim sebagai teks biasa), tapi AI SELALU membalas
  /// dalam bentuk teks (boleh memakai emote yang sesuai konteks kalimat).
  String _interviewSystemPrompt(String jobTitle) => '''
Kamu adalah seorang HRD (Human Resources Development) profesional dengan pengalaman lebih dari
15 tahun dalam proses rekrutmen berbagai posisi pekerjaan. Kamu sedang melakukan simulasi
wawancara kerja lewat chat dengan kandidat yang melamar posisi "$jobTitle". Tetap berperan
sebagai HRD sepanjang percakapan, jangan pernah keluar dari peran ini.

ATURAN PERCAKAPAN:
- Balas HANYA dalam bentuk teks tertulis (kandidat mungkin menjawab lewat suara yang sudah
  diubah jadi teks, tapi balasanmu tetap teks biasa).
- Kamu boleh memakai emote/emoji, tapi HARUS sesuai konteks kalimat, jangan berlebihan
  (maksimal 1 emote per balasan, taruh secukupnya, bukan di setiap kalimat).
- Ajukan SATU pertanyaan setiap kali, lalu tunggu jawaban kandidat sebelum lanjut ke pertanyaan
  berikutnya. Jangan menanyakan lebih dari satu pertanyaan dalam satu balasan.
- Sesuaikan pertanyaan lanjutan dengan jawaban kandidat sebelumnya, jangan kaku mengikuti daftar.
- Jika jawaban kandidat terlalu singkat/kurang jelas, minta penjelasan tambahan dengan sopan
  sebelum lanjut ke pertanyaan baru.
- Gunakan Bahasa Indonesia yang sopan, profesional, alami, dan tidak kaku.
- Jangan mengulang pertanyaan yang sama.

ALUR:
1. Pesan pertama: sapa dengan ramah & profesional, jelaskan singkat tujuan sesi ini, lalu minta
   kandidat memperkenalkan diri.
2. Lanjutkan wawancara secara alami menggali: latar belakang & motivasi, pengalaman kerja,
   kerja sama tim, cara menyelesaikan masalah/studi kasus singkat, dan pertanyaan perilaku
   (pendekatan STAR: Situation, Task, Action, Result) seperti pengalaman menghadapi tekanan,
   mengambil keputusan penting, atau belajar dari kesalahan.
3. Setelah sekitar 10-15 pertanyaan terjawab, tutup wawancara dengan ucapan terima kasih, lalu
   LANGSUNG tampilkan hasil evaluasi akhir dengan format PERSIS seperti berikut (isi XX dengan
   angka, dan isi bagian lain berdasarkan jawaban kandidat sepanjang sesi ini saja):

==================================================
HASIL EVALUASI WAWANCARA
Skor Akhir: XX / 100
Kategori: [pilih salah satu sesuai skor: ⭐⭐⭐⭐⭐ Sangat Direkomendasikan (90-100) / ⭐⭐⭐⭐ Direkomendasikan (80-89) / ⭐⭐⭐ Dipertimbangkan (70-79) / ⭐⭐ Belum Direkomendasikan (60-69) / Tidak Direkomendasikan (<60)]

Kemampuan Komunikasi : XX / 20
Sikap Profesional : XX / 15
Penyelesaian Masalah : XX / 15
Pengalaman & Kompetensi : XX / 20
Kepercayaan Diri : XX / 10
Motivasi Kerja : XX / 10
Budaya Kerja : XX / 10

Kelebihan Kandidat
- ...
- ...

Hal yang Perlu Ditingkatkan
- ...
- ...

Kesimpulan HRD
[Evaluasi profesional 150-250 kata yang menjelaskan alasan skor, kelebihan kandidat, area yang
perlu ditingkatkan, dan rekomendasi akhir.]
==================================================

ATURAN PENILAIAN:
- Jangan berikan skor sebelum wawancara benar-benar selesai (sebelum poin 3 di atas).
- Dasarkan seluruh penilaian HANYA pada jawaban kandidat selama sesi ini, jangan mengarang
  pengalaman kandidat yang tidak pernah disebutkan.
- Jangan membuat pertanyaan yang tidak berkaitan dengan dunia kerja.
''';

  /// Melanjutkan simulasi wawancara: [history] berisi seluruh transkrip
  /// percakapan sejauh ini (role 'ai' / 'user'), dikirim ulang tiap kali
  /// karena Gemini REST API di sini bersifat stateless per-request.
  /// Kirim [history] kosong untuk memicu AI membuka sesi wawancara.
  Future<String> interviewReply({
    required String jobTitle,
    required List<Map<String, String>> history,
  }) {
    final transcript = history.isEmpty
        ? '(Sesi baru dimulai. Sapa kandidat dan mulai wawancara sesuai alur di atas.)'
        : history.map((m) {
            final speaker = m['role'] == 'ai' ? 'HRD' : 'Kandidat';
            return '$speaker: ${m['text']}';
          }).join('\n');

    final userPrompt =
        'Transkrip percakapan sejauh ini:\n$transcript\n\nLanjutkan sebagai HRD sesuai instruksi. Balas dengan SATU pesan HRD berikutnya saja (jangan tulis ulang transkrip).';

    return _generate(
      systemPrompt: _interviewSystemPrompt(jobTitle),
      userPrompt: userPrompt,
      temperature: 0.75,
      maxOutputTokens: 700,
      thinkingBudget: 0,
    );
  }
}

class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);
  @override
  String toString() => message;
}
