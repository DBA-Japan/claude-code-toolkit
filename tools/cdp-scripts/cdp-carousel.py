#!/usr/bin/env python3
"""
FRAA 3Dカルーセルの desktop と mobile 表示を検証＆スクショ
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


async def capture(ws, url, width, height, scroll_y, out_path):
    await cdp_call(ws, "Emulation.setDeviceMetricsOverride", {
        "width": width, "height": height,
        "deviceScaleFactor": 2 if width < 500 else 1,
        "mobile": width < 500
    })
    await cdp_call(ws, "Page.navigate", {"url": url})
    await asyncio.sleep(3)
    await cdp_call(ws, "Runtime.evaluate", {
        "expression": f"window.scrollTo({{top: {scroll_y}, behavior: 'instant'}});"
    })
    await asyncio.sleep(1)
    # アニメ途中を撮るため、少し animation を進めたタイミング
    result, _ = await cdp_call(ws, "Page.captureScreenshot", {"format": "png"})
    with open(out_path, "wb") as f:
        f.write(base64.b64decode(result["data"]))
    print(f"OK: {out_path}")

    # 検証: CSS 変数と transform
    check, _ = await cdp_call(ws, "Runtime.evaluate", {
        "expression": """
            (() => {
                const stage = document.querySelector('.highlights-stage');
                const pivot = document.querySelector('.highlights-pivot');
                const cards = document.querySelectorAll('.hl-card');
                const stageStyle = getComputedStyle(stage);
                const cardStyles = Array.from(cards).slice(0, 3).map(c => {
                    const s = getComputedStyle(c);
                    return {
                        width: s.width,
                        height: s.height,
                        transform: s.transform.substring(0, 80)
                    };
                });
                return {
                    stage_container: stageStyle.containerType,
                    stage_perspective: stageStyle.perspective,
                    hl_radius: stageStyle.getPropertyValue('--hl-radius').trim(),
                    hl_perspective: stageStyle.getPropertyValue('--hl-perspective').trim(),
                    hl_tilt: stageStyle.getPropertyValue('--hl-tilt').trim(),
                    hl_card_w: stageStyle.getPropertyValue('--hl-card-w').trim(),
                    hl_card_h: stageStyle.getPropertyValue('--hl-card-h').trim(),
                    pivot_transform: getComputedStyle(pivot).transform.substring(0, 80),
                    card_count: cards.length,
                    sample_cards: cardStyles
                };
            })()
        """,
        "returnByValue": True
    })
    return check["result"]["value"]


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

            # Desktop
            print("\n=== Desktop (1440x900) ===")
            data = await capture(ws, url, 1440, 900, 3500, "/tmp/fraa-carousel-desktop.png")
            print(json.dumps(data, indent=2))

            # Mobile (iPhone 14 Pro)
            print("\n=== Mobile (390x844) ===")
            data = await capture(ws, url, 390, 844, 2200, "/tmp/fraa-carousel-mobile.png")
            print(json.dumps(data, indent=2))

    finally:
        requests.get(f"{CDP_URL}/json/close/{tab_id}")


if __name__ == "__main__":
    asyncio.run(main())
