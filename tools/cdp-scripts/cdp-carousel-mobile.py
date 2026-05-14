#!/usr/bin/env python3
"""
FRAA モバイル版の Highlights セクションに正確にスクロールして撮影
"""
import asyncio
import base64
import json
import requests
import websockets

CDP_URL = "http://127.0.0.1:9222"


async def cdp_call(ws, method, params=None, req_id=[0]):
    req_id[0] += 1
    msg = {"id": req_id[0], "method": method}
    if params:
        msg["params"] = params
    await ws.send(json.dumps(msg))
    while True:
        raw = await ws.recv()
        data = json.loads(raw)
        if data.get("id") == req_id[0]:
            return data.get("result", {}), data.get("error")


async def main():
    url = "http://localhost:9987/index.html"
    r = requests.put(f"{CDP_URL}/json/new?about:blank")
    tab = r.json()
    ws_url = tab["webSocketDebuggerUrl"]
    tab_id = tab["id"]

    try:
        async with websockets.connect(ws_url, max_size=50_000_000) as ws:
            await cdp_call(ws, "Page.enable")
            await cdp_call(ws, "Runtime.enable")

            # Mobile
            await cdp_call(ws, "Emulation.setDeviceMetricsOverride", {
                "width": 390, "height": 844,
                "deviceScaleFactor": 2, "mobile": True
            })
            await cdp_call(ws, "Page.navigate", {"url": url})
            await asyncio.sleep(3)

            # highlights セクションへスクロール
            await cdp_call(ws, "Runtime.evaluate", {
                "expression": "document.querySelector('.highlights').scrollIntoView({block: 'start'}); window.scrollBy(0, 40);"
            })
            await asyncio.sleep(1)

            # 現在のスクロール位置を確認
            sp = await cdp_call(ws, "Runtime.evaluate", {
                "expression": "JSON.stringify({y: window.scrollY, hl_rect: document.querySelector('.highlights').getBoundingClientRect().top, stage_rect: document.querySelector('.highlights-stage').getBoundingClientRect().top})",
                "returnByValue": True
            })
            print(sp[0]["result"]["value"])

            result, _ = await cdp_call(ws, "Page.captureScreenshot", {"format": "png"})
            with open("/tmp/fraa-carousel-mobile2.png", "wb") as f:
                f.write(base64.b64decode(result["data"]))
            print("OK: /tmp/fraa-carousel-mobile2.png")

            # 少し下にスクロールしてステージ中央へ
            await cdp_call(ws, "Runtime.evaluate", {
                "expression": "document.querySelector('.highlights-stage').scrollIntoView({block: 'center'});"
            })
            await asyncio.sleep(1)

            result, _ = await cdp_call(ws, "Page.captureScreenshot", {"format": "png"})
            with open("/tmp/fraa-carousel-mobile-center.png", "wb") as f:
                f.write(base64.b64decode(result["data"]))
            print("OK: /tmp/fraa-carousel-mobile-center.png")

    finally:
        requests.get(f"{CDP_URL}/json/close/{tab_id}")


if __name__ == "__main__":
    asyncio.run(main())
