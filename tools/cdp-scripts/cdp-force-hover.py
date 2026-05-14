#!/usr/bin/env python3
"""
CSS.forcePseudoState を使って :hover を強制発動し :has() dim を証明
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
            await cdp_call(ws, "DOM.enable")
            await cdp_call(ws, "CSS.enable")
            await cdp_call(ws, "Emulation.setDeviceMetricsOverride", {
                "width": 1440, "height": 900,
                "deviceScaleFactor": 1, "mobile": False
            })
            await cdp_call(ws, "Page.navigate", {"url": url})
            await asyncio.sleep(3)

            # athletes セクションまでスクロール
            await cdp_call(ws, "Runtime.evaluate", {
                "expression": "document.querySelector('.athletes-grid').scrollIntoView({block: 'start'}); window.scrollBy(0, -80);"
            })
            await asyncio.sleep(0.5)

            # DOM の root を取得
            doc, _ = await cdp_call(ws, "DOM.getDocument", {"depth": -1})
            root_id = doc["root"]["nodeId"]

            # 5個目のカードを選択
            query_result, _ = await cdp_call(ws, "DOM.querySelectorAll", {
                "nodeId": root_id,
                "selector": ".athlete-card"
            })
            card_ids = query_result["nodeIds"]
            print(f"Found {len(card_ids)} athlete cards")
            target_card_id = card_ids[4]

            # :hover を強制発動
            await cdp_call(ws, "CSS.forcePseudoState", {
                "nodeId": target_card_id,
                "forcedPseudoClasses": ["hover"]
            })
            await asyncio.sleep(0.6)

            # スクショ
            result, _ = await cdp_call(ws, "Page.captureScreenshot", {"format": "png"})
            with open("/tmp/fraa-has-dim.png", "wb") as f:
                f.write(base64.b64decode(result["data"]))
            print("OK: /tmp/fraa-has-dim.png")

            # 各カードの computed style を確認
            check, _ = await cdp_call(ws, "Runtime.evaluate", {
                "expression": """
                    (() => {
                        const cards = document.querySelectorAll('.athlete-card');
                        return Array.from(cards).map((c, i) => {
                            const s = getComputedStyle(c);
                            return {
                                i: i,
                                opacity: s.opacity,
                                filter: s.filter.substring(0, 50),
                                matches_not_hover: c.matches(':not(:hover)')
                            };
                        });
                    })()
                """,
                "returnByValue": True
            })
            print("\n=== 各カードの状態（5番目に :hover 強制） ===")
            for item in check["result"]["value"]:
                marker = "🎯" if item["i"] == 4 else "  "
                print(f"{marker} card[{item['i']}]: opacity={item['opacity']}, filter={item['filter']}")

            # :hover を解除
            await cdp_call(ws, "CSS.forcePseudoState", {
                "nodeId": target_card_id,
                "forcedPseudoClasses": []
            })

    finally:
        requests.get(f"{CDP_URL}/json/close/{tab_id}")


if __name__ == "__main__":
    asyncio.run(main())
