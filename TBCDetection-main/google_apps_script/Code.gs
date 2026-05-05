/**
 * Google Apps Script — TBC Detection Backend
 *
 * Sheet "Gejala"  : id | question | hint | sortOrder | active
 * Sheet "Diagnosa": timestamp | conclusion_id | conclusion_title | certainty | active_symptoms
 *
 * Script Properties: ADMIN_TOKEN = (kata sandi admin)
 *
 * Deploy > Deployment baru > Jenis: Aplikasi web
 *   - Jalankan sebagai: Saya
 *   - Siapa yang memiliki akses: Siapa saja
 */

var SHEET_NAME    = 'Gejala';
var DIAGNOSA_SHEET = 'hasil_diagnosa';
var ADMIN_SHEET    = 'Admin';

function jsonOut_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
      .setMimeType(ContentService.MimeType.JSON);
}

function checkAuth_(body) {
  var token = String(body.token || body.password || '').trim();
  if (!token) return false;
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(ADMIN_SHEET);
  if (!sh) return false;
  var values = sh.getDataRange().getValues();
  if (values.length < 2) return false;
  var headers = values[0].map(function(h) { return String(h).toLowerCase().trim(); });
  var passCol = headers.indexOf('password');
  if (passCol < 0) return false;
  for (var i = 1; i < values.length; i++) {
    if (String(values[i][passCol] || '').trim() === token) return true;
  }
  return false;
}

// ── Sheet Gejala ──────────────────────────────────────────────────────────────

function ensureSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(SHEET_NAME);
  if (!sh) {
    sh = ss.insertSheet(SHEET_NAME);
    sh.getRange(1, 1, 1, 5).setValues([['id', 'question', 'hint', 'sortOrder', 'active']]);
    sh.setFrozenRows(1);
  } else {
    var h = sh.getRange(1, 1, 1, 1).getValue();
    if (String(h).toLowerCase() !== 'id') {
      sh.insertRowBefore(1);
      sh.getRange(1, 1, 1, 5).setValues([['id', 'question', 'hint', 'sortOrder', 'active']]);
      sh.setFrozenRows(1);
    }
  }
  return sh;
}

function readSymptoms_(sh, activeOnly) {
  var values = sh.getDataRange().getValues();
  if (values.length < 2) return [];
  var out = [];
  for (var r = 1; r < values.length; r++) {
    var row = values[r];
    var id  = String(row[0] || '').trim();
    if (!id) continue;
    var active = row[4] === true || String(row[4]).toUpperCase() === 'TRUE'
              || row[4] === 1   || String(row[4]) === '1';
    if (activeOnly && !active) continue;
    var so = Number(row[3]);
    if (isNaN(so)) so = r;
    out.push({ id: id, question: String(row[1] || ''), hint: String(row[2] || ''),
               sortOrder: so, active: active });
  }
  out.sort(function(a, b) { return a.sortOrder - b.sortOrder; });
  return out;
}

// ── Sheet Diagnosa ────────────────────────────────────────────────────────────

function ensureDiagnosaSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(DIAGNOSA_SHEET);
  if (!sh) {
    sh = ss.insertSheet(DIAGNOSA_SHEET);
    sh.getRange(1, 1, 1, 6).setValues([
      ['id_hasil', 'timestamp', 'id_user', 'hasil_utama_kode', 'hasil_utama_nilai_cf', 'detail_jawaban_json']
    ]);
    sh.setFrozenRows(1);
  }
  return sh;
}

function saveDiagnosa_(data) {
  var sh      = ensureDiagnosaSheet_();
  var idHasil = sh.getLastRow();  // header=1, baris ke-2 → id=1, dst.
  sh.appendRow([
    idHasil,
    data.timestamp || new Date().toISOString(),
    String(data.id_user || ''),
    String(data.hasil_utama_kode || ''),
    String(data.hasil_utama_nilai_cf || ''),
    String(data.detail_jawaban_json || ''),
  ]);
  return jsonOut_({ ok: true });
}

function listDiagnosa_() {
  var sh     = ensureDiagnosaSheet_();
  var values = sh.getDataRange().getValues();
  if (values.length < 2) return [];
  var out = [];
  for (var r = values.length - 1; r >= 1; r--) {  // terbaru di atas
    var row = values[r];
    out.push({
      id_hasil:             String(row[0] || ''),
      timestamp:            String(row[1] || ''),
      id_user:              String(row[2] || ''),
      hasil_utama_kode:     String(row[3] || ''),
      hasil_utama_nilai_cf: String(row[4] || ''),
      detail_jawaban_json:  String(row[5] || ''),
    });
  }
  return out;
}

// ── HTTP Handlers ─────────────────────────────────────────────────────────────

function doGet() {
  try {
    var sh = ensureSheet_();
    return jsonOut_({ ok: true, symptoms: readSymptoms_(sh, true) });
  } catch (err) {
    return jsonOut_({ ok: false, error: String(err) });
  }
}

function doPost(e) {
  try {
    if (!e.postData || !e.postData.contents) {
      return jsonOut_({ ok: false, error: 'Body kosong' });
    }
    var body = JSON.parse(e.postData.contents);

    // saveDiagnosa: tidak perlu auth (dipanggil dari device pengguna)
    if (body.action === 'saveDiagnosa') {
      return saveDiagnosa_(body.diagnosa || {});
    }

    // Semua aksi admin memerlukan auth
    if (!checkAuth_(body)) {
      return jsonOut_({ ok: false, error: 'Unauthorized' });
    }

    if (body.action === 'listDiagnosa') {
      return jsonOut_({ ok: true, data: listDiagnosa_() });
    }
    if (body.action === 'listSymptoms') {
      return jsonOut_({ ok: true, symptoms: readSymptoms_(ensureSheet_(), false) });
    }
    if (body.action === 'saveSymptom') {
      return saveSymptom_(body.symptom);
    }

    return jsonOut_({ ok: false, error: 'Aksi tidak dikenal' });
  } catch (err) {
    return jsonOut_({ ok: false, error: String(err) });
  }
}

function saveSymptom_(symptom) {
  var sh     = ensureSheet_();
  var values = sh.getDataRange().getValues();
  var id = String(symptom.id || '').trim().toLowerCase()
      .replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
  if (!id) return jsonOut_({ ok: false, error: 'ID wajib (huruf, angka, garis bawah)' });
  var so     = Number(symptom.sortOrder); if (isNaN(so)) so = 999;
  var active = symptom.active === false ? false : true;
  var rowIndex = -1;
  for (var r = 1; r < values.length; r++) {
    if (String(values[r][0] || '').trim().toLowerCase() === id) { rowIndex = r + 1; break; }
  }
  var rowData = [id, String(symptom.question || ''), String(symptom.hint || ''), so, active];
  if (rowIndex > 0) {
    sh.getRange(rowIndex, 1, 1, 5).setValues([rowData]);
  } else {
    sh.appendRow(rowData);
  }
  return jsonOut_({ ok: true });
}
