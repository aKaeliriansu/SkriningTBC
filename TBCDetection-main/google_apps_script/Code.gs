/**
 * Google Apps Script — tempel di editor terikat Spreadsheet (Ekstensi > Apps Script).
 *
 * 1. Buat / gunakan Spreadsheet. Script ini membuat sheet "Gejala" jika belum ada.
 * 2. Project Settings > Script properties: tambah ADMIN_TOKEN = (kata sandi rahasia admin).
 * 3. Deploy > Deployment baru > Jenis: Aplikasi web
 *    - Jalankan sebagai: Saya
 *    - Siapa yang memiliki akses: Siapa saja (untuk GET gejala aktif dari aplikasi)
 * 4. Salin URL Web App ke aplikasi Flutter (tanpa menyertakan token di URL).
 *
 * Kolom sheet Gejala: id | question | hint | sortOrder | active
 */

var SHEET_NAME = 'Gejala';

function jsonOut_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

function getAdminToken_() {
  return PropertiesService.getScriptProperties().getProperty('ADMIN_TOKEN') || '';
}

function ensureSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName(SHEET_NAME);
  if (!sh) {
    sh = ss.insertSheet(SHEET_NAME);
    sh.getRange(1, 1, 1, 5).setValues([['id', 'question', 'hint', 'sortOrder', 'active']]);
  } else {
    var h = sh.getRange(1, 1, 1, 5).getValues()[0];
    if (String(h[0]).toLowerCase() !== 'id') {
      sh.insertRowBefore(1);
      sh.getRange(1, 1, 1, 5).setValues([['id', 'question', 'hint', 'sortOrder', 'active']]);
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
    var id = String(row[0] || '').trim();
    if (!id) continue;
    var question = String(row[1] || '');
    var hint = String(row[2] || '');
    var sortOrder = row[3];
    sortOrder = sortOrder === '' || sortOrder === null ? r : Number(sortOrder);
    if (isNaN(sortOrder)) sortOrder = r;
    var av = row[4];
    var active = av === true || String(av).toUpperCase() === 'TRUE' || av === 1 || String(av) === '1';
    if (activeOnly && !active) continue;
    out.push({
      id: id,
      question: question,
      hint: hint,
      sortOrder: sortOrder,
      active: active,
    });
  }
  out.sort(function (a, b) {
    return a.sortOrder - b.sortOrder;
  });
  return out;
}

function doGet() {
  try {
    var sh = ensureSheet_();
    var symptoms = readSymptoms_(sh, true);
    return jsonOut_({ ok: true, symptoms: symptoms });
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
    var token = body.token || '';
    var expected = getAdminToken_();
    if (!expected || token !== expected) {
      return jsonOut_({ ok: false, error: 'Unauthorized' });
    }
    if (body.action === 'listSymptoms') {
      var sh = ensureSheet_();
      return jsonOut_({ ok: true, symptoms: readSymptoms_(sh, false) });
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
  var sh = ensureSheet_();
  var values = sh.getDataRange().getValues();
  var id = String(symptom.id || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_]/g, '');
  if (!id) return jsonOut_({ ok: false, error: 'ID wajib (huruf, angka, garis bawah)' });
  var question = String(symptom.question || '');
  var hint = String(symptom.hint || '');
  var so = Number(symptom.sortOrder);
  if (isNaN(so)) so = 999;
  var active = symptom.active === false ? false : true;
  var rowIndex = -1;
  for (var r = 1; r < values.length; r++) {
    var existing = String(values[r][0] || '')
      .trim()
      .toLowerCase();
    if (existing === id) {
      rowIndex = r + 1;
      break;
    }
  }
  if (rowIndex > 0) {
    sh.getRange(rowIndex, 1, rowIndex, 5).setValues([[id, question, hint, so, active]]);
  } else {
    sh.appendRow([id, question, hint, so, active]);
  }
  return jsonOut_({ ok: true });
}
