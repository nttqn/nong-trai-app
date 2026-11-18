// Capture clean farm "plates" (large viewport; HUD is cropped away later).
const { chromium } = require('playwright');
const out = process.argv[2];
const base = 'demo=3&shot=1&weather=sunny';
const plates = [
  ['wide', `${base}&day=2026-11-06&fx=13&fy=11&zoom=0.95`, 1500, 1300],
  ['fields', `${base}&day=2026-11-06&ripe=1&fx=15&fy=9&zoom=1.35`, 1300, 1500],
  ['tet', `${base}&day=2027-02-06&fest=1&fx=5&fy=13&zoom=1.4`, 1300, 1500],
  ['pens', `${base}&day=2026-11-06&fx=8&fy=16&zoom=1.45`, 1300, 1500],
];
(async () => {
  const browser = await chromium.launch();
  for (const [name, q, w, h] of plates) {
    if (process.argv[3] && name !== process.argv[3]) continue;
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
    const page = await ctx.newPage();
    await page.goto(`http://localhost:8790/?${q}&nocache=${Date.now()}`);
    await page.waitForTimeout(13000);
    await page.screenshot({ path: `${out}/plate-${name}.png` });
    await ctx.close();
  }
  await browser.close();
})();
