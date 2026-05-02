/**
 * Unduh HTML/gambar tanpa SDK: isi stitch_urls.json lalu jalankan:
 *   node download_from_urls.mjs
 *
 * URL bisa dari ekspor Stitch (More > Export), salinan link unduhan,
 * atau dari output getHtml()/getImage() setelah autentikasi OAuth berhasil.
 *
 * PowerShell (setara curl -L):
 *   node download_from_urls.mjs
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MANIFEST = path.join(__dirname, "stitch_urls.json");
const OUT_DIR = path.join(__dirname, "..", "..", "assets", "stitch");

if (!fs.existsSync(MANIFEST)) {
  console.error("File tidak ada:", MANIFEST);
  console.error("Salin stitch_urls.example.json -> stitch_urls.json dan isi URL-nya.");
  process.exit(1);
}

const data = JSON.parse(fs.readFileSync(MANIFEST, "utf8"));
await fs.promises.mkdir(OUT_DIR, { recursive: true });

async function download(url, dest) {
  const res = await fetch(url, { redirect: "follow" });
  if (!res.ok) throw new Error(`${dest}: HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  await fs.promises.writeFile(dest, buf);
  console.log("OK", dest, buf.length, "bytes");
}

for (const [slug, urls] of Object.entries(data)) {
  if (typeof urls !== "object" || !urls) continue;
  if (urls.html && String(urls.html).startsWith("http")) {
    const text = await fetch(urls.html, { redirect: "follow" }).then((r) => {
      if (!r.ok) throw new Error(`html ${slug}: ${r.status}`);
      return r.text();
    });
    await fs.promises.writeFile(path.join(OUT_DIR, `${slug}.html`), text, "utf8");
    console.log("OK", `${slug}.html`, text.length, "chars");
  }
  if (urls.image && String(urls.image).startsWith("http")) {
    const ext = urls.imageExt || guessExt(urls.image);
    await download(urls.image, path.join(OUT_DIR, `${slug}.${ext}`));
  }
}

function guessExt(u) {
  if (u.includes(".png")) return "png";
  if (u.includes(".webp")) return "webp";
  if (u.includes(".jpg") || u.includes(".jpeg")) return "jpg";
  return "png";
}

console.log("Selesai ->", OUT_DIR);
