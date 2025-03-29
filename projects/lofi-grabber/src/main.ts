import { Browser, BrowserErrorCaptureEnum } from "happy-dom";

const browser = new Browser({
    settings: {
        errorCapture: BrowserErrorCaptureEnum.processLevel
    }
})
const page = browser.newPage();

await page.goto("https://lofigirl.com/releases/");
await page.waitUntilComplete();
const document = page.mainFrame.document;

document.querySelector("jet-listing-grid-loading").focus();
await page.waitUntilComplete();

console.log([...document.querySelectorAll(".jet-entine-listing-overlay-link")].map(p => p.href))

export {}
