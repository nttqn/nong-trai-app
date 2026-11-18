const { chromium } = require('playwright');
const { pathToFileURL } = require('url');
const sizes = { land: [1200, 628], sq: [1200, 1200], port: [1200, 1500] };
(async () => {
  const b = await chromium.launch({ args: ['--allow-file-access-from-files'] });
  const page = await b.newPage({ viewport: { width: 1200, height: 1500 } });
  for (const c of (process.argv[2] || 'ABCD').split('')) for (const [s, [w, h]] of Object.entries(sizes)) {
    await page.goto(pathToFileURL('compose.html').href + `?c=${c}&s=${s}`);
    await page.waitForFunction(() => document.title === 'ready');
    await page.waitForTimeout(300);
    await page.locator('#ad').screenshot({ path: `out/${c}-${s}-${w}x${h}.jpg`, type: 'jpeg', quality: 90 });
  }
  await b.close();
})();
