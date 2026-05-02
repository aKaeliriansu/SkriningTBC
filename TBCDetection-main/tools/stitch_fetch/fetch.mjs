/**
 * Unduh HTML + screenshot layar Stitch ke ../../assets/stitch/
 *
 * Autentikasi MCP Stitch (saat ini umumnya OAuth, bukan API key saja):
 *   $env:STITCH_ACCESS_TOKEN="ya29...."
 *   $env:GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
 *   node fetch.mjs
 * Jangan set STITCH_API_KEY bersamaan jika server menolak API key.
 *
 * Alternatif tanpa SDK: isi stitch_urls.json + node download_from_urls.mjs
 *
 * Proyek: Skrining Mandiri TB — ID 1146388961447793069
 */

import { stitch } from "@google/stitch-sdk";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_DIR = path.join(__dirname, "..", "..", "assets", "stitch");

const PROJECT_ID = "1146388961447793069";
const SCREENS = [
  { id: "329068f14d7d4e2aa2d199dc0ad955e8", slug: "informasi_tbc" },
  { id: "7eebd629032b4d58af6e7ac24bce2bfe", slug: "skrining_gejala" },
];

const hasOAuth =
  process.env.STITCH_ACCESS_TOKEN?.trim() && process.env.GOOGLE_CLOUD_PROJECT?.trim();
const hasApiKey = process.env.STITCH_API_KEY?.trim();

if (!hasOAuth && !hasApiKey) {
  console.error("Butuh salah satu:");
  console.error("  OAuth: STITCH_ACCESS_TOKEN + GOOGLE_CLOUD_PROJECT");
  console.error("  atau API key: STITCH_API_KEY (jika layanan Anda mendukungnya)");
  console.error("Atau pakai: node download_from_urls.mjs dengan stitch_urls.json");
  process.exit(1);
}

if (hasOAuth) {
  delete process.env.STITCH_API_KEY;
}

await fs.promises.mkdir(OUT_DIR, { recursive: true });

const project = stitch.project(PROJECT_ID);

for (const s of SCREENS) {
  console.log("Fetching screen", s.slug, s.id);
  const screen = await project.getScreen(s.id);
  const htmlUrl = await screen.getHtml();
  const imageUrl = await screen.getImage();
  if (!htmlUrl) {
    console.error("No HTML URL for", s.slug);
    continue;
  }
  console.log("  HTML:", htmlUrl);
  console.log("  Image:", imageUrl || "(none)");

  const htmlRes = await fetch(htmlUrl);
  if (!htmlRes.ok) throw new Error(`HTML fetch ${htmlRes.status}`);
  const html = await htmlRes.text();
  await fs.promises.writeFile(path.join(OUT_DIR, `${s.slug}.html`), html, "utf8");

  if (imageUrl) {
    const imgRes = await fetch(imageUrl);
    if (!imgRes.ok) throw new Error(`Image fetch ${imgRes.status}`);
    const buf = Buffer.from(await imgRes.arrayBuffer());
    const ct = (imgRes.headers.get("content-type") || "").toLowerCase();
    const ext = ct.includes("png")
      ? "png"
      : ct.includes("webp")
        ? "webp"
        : ct.includes("jpeg") || ct.includes("jpg")
          ? "jpg"
          : "png";
    await fs.promises.writeFile(path.join(OUT_DIR, `${s.slug}.${ext}`), buf);
    console.log("  Wrote", `${s.slug}.${ext}`, buf.length, "bytes");
  }
  console.log("  Wrote", `${s.slug}.html`);
}

if (typeof stitch.close === "function") {
  await stitch.close();
}
console.log("Done. Output:", OUT_DIR);
