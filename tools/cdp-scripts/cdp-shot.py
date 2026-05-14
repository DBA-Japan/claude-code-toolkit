#!/usr/bin/env python3
"""
CDP (Chrome DevTools Protocol) でスクリーンショットを取るスクリプト。
既存の Chrome at 127.0.0.1:9222 に接続して、URLを開きスクロール・スクショ取得。
"""
import asyncio
import base64
import json
import sys
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


async def screenshot(target_url, output_path, scroll_y=0, wait_ms=2000):
    # 新しいタブを作成
    r = requests.put(f"{CDP_URL}/json/new?about:blank")
    tab = r.json()
    ws_url = tab["webSocketDebuggerUrl"]
    tab_id = tab["id"]

    try:
        async with websockets.connect(ws_url, max_size=50_000_000) as ws:
            await cdp_call(ws, "Page.enable")
            await cdp_call(ws, "Runtime.enable")
            # viewport 設定
            await cdp_call(ws, "Emulation.setDeviceMetricsOverride", {
                "width": 1440, "height": 900,
                "deviceScaleFactor": 1, "mobile": False
            })
            # ナビゲート
            await cdp_call(ws, "Page.navigate", {"url": target_url})
            # loadイベント待機の代わりに少し待つ
            await asyncio.sleep(wait_ms / 1000)
            # スクロール
            if scroll_y > 0:
                await cdp_call(ws, "Runtime.evaluate", {
                    "expression": f"window.scrollTo({{top: {scroll_y}, behavior: 'instant'}});"
                })
                await asyncio.sleep(0.5)
            # スクショ取得
            result, err = await cdp_call(ws, "Page.captureScreenshot", {
                "format": "png", "fromSurface": True
            })
            if err:
                print(f"ERROR: {err}", file=sys.stderr)
                return False
            img_data = base64.b64decode(result["data"])
            with open(output_path, "wb") as f:
                f.write(img_data)
            print(f"OK: {output_path} ({len(img_data)} bytes)")
            return True
    finally:
        # タブ閉じる
        requests.get(f"{CDP_URL}/json/close/{tab_id}")


async def main():
    url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:9987/index.html"
    output = sys.argv[2] if len(sys.argv) > 2 else "/tmp/cdp-shot.png"
    scroll = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    await screenshot(url, output, scroll_y=scroll)


if __name__ == "__main__":
    asyncio.run(main())
