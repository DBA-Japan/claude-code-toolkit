#!/usr/bin/env python3
"""
FRAA に投入した Modern CSS 2026 全5武器が実際に動いてるかを JS 評価で検証する。
"""
import asyncio
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


async def eval_js(ws, expression):
    result, err = await cdp_call(ws, "Runtime.evaluate", {
        "expression": expression,
        "returnByValue": True,
        "awaitPromise": True,
    })
    if err:
        return f"ERROR: {err}"
    val = result.get("result", {}).get("value")
    return val


async def main():
    url = "http://localhost:9987/index.html"
    # 新しいタブ
    r = requests.put(f"{CDP_URL}/json/new?about:blank")
    tab = r.json()
    ws_url = tab["webSocketDebuggerUrl"]
    tab_id = tab["id"]

    try:
        async with websockets.connect(ws_url, max_size=50_000_000) as ws:
            await cdp_call(ws, "Page.enable")
            await cdp_call(ws, "Runtime.enable")
            await cdp_call(ws, "Emulation.setDeviceMetricsOverride", {
                "width": 1440, "height": 900,
                "deviceScaleFactor": 1, "mobile": False
            })
            await cdp_call(ws, "Page.navigate", {"url": url})
            await asyncio.sleep(3)

            print("=" * 60)
            print("FRAA Modern CSS 2026 — 動作検証")
            print("=" * 60)

            # Browser UA
            ua = await eval_js(ws, "navigator.userAgent")
            print(f"\n[環境] UA: {ua[:80]}")

            # 1. Scroll-driven Animation support
            print("\n--- 武器1: Scroll-driven Animation ---")
            sda = await eval_js(ws, "CSS.supports('animation-timeline', 'view()')")
            print(f"CSS.supports('animation-timeline', 'view()') = {sda}")

            reveal_anim = await eval_js(ws, """
                (() => {
                    const el = document.querySelector('.reveal');
                    if (!el) return 'no .reveal element';
                    const s = getComputedStyle(el);
                    return {
                        'animation-timeline': s.animationTimeline,
                        'animation-name': s.animationName,
                        'animation-range': s.getPropertyValue('animation-range-start') + ' ' + s.getPropertyValue('animation-range-end')
                    };
                })()
            """)
            print(f".reveal computed: {reveal_anim}")

            progress_anim = await eval_js(ws, """
                (() => {
                    const el = document.querySelector('.scroll-progress');
                    if (!el) return 'no .scroll-progress element';
                    const s = getComputedStyle(el);
                    return {
                        'animation-timeline': s.animationTimeline,
                        'animation-name': s.animationName,
                        'position': s.position,
                        'top': s.top,
                        'height': s.height
                    };
                })()
            """)
            print(f".scroll-progress: {progress_anim}")

            # 2. View Transitions
            print("\n--- 武器2: View Transitions API ---")
            vt = await eval_js(ws, "'startViewTransition' in document")
            print(f"document.startViewTransition available = {vt}")

            # 3. @starting-style
            print("\n--- 武器3: @starting-style ---")
            ss = await eval_js(ws, "CSS.supports('selector(@starting-style)') || CSS.supports('animation-composition', 'add')")
            print(f"@starting-style support (approx) = {ss}")

            # 4. Container Queries
            print("\n--- 武器4: Container Queries ---")
            cq = await eval_js(ws, "CSS.supports('container-type', 'inline-size')")
            print(f"CSS.supports('container-type', 'inline-size') = {cq}")

            athletes_container = await eval_js(ws, """
                (() => {
                    const el = document.querySelector('.athletes');
                    if (!el) return 'no .athletes element';
                    const s = getComputedStyle(el);
                    return {
                        'container-type': s.containerType,
                        'container-name': s.containerName
                    };
                })()
            """)
            print(f".athletes: {athletes_container}")

            # 5. :has() selector
            print("\n--- 武器5: :has() selector ---")
            has_support = await eval_js(ws, "CSS.supports('selector(:has(*))')")
            print(f"CSS.supports('selector(:has(*))') = {has_support}")

            # body:has() の動作テスト
            # nav-overlay に open class を追加して body の overflow が hidden になるか
            has_test = await eval_js(ws, """
                (() => {
                    const overlay = document.querySelector('.nav-overlay');
                    if (!overlay) return 'no .nav-overlay';
                    // 一時的に open を付与
                    overlay.classList.add('open');
                    const bodyOverflow = getComputedStyle(document.body).overflow;
                    overlay.classList.remove('open');
                    return {
                        'body overflow when menu open': bodyOverflow,
                        'expected': 'hidden'
                    };
                })()
            """)
            print(f":has() body lock test: {has_test}")

            # .athletes-grid の hover 時の他カード dim のセレクタが効くか
            has_selector_test = await eval_js(ws, """
                (() => {
                    // セレクタとしてマッチするか
                    const rules = [];
                    for (const ss of document.styleSheets) {
                        try {
                            for (const r of ss.cssRules) {
                                if (r.selectorText && r.selectorText.includes(':has(')) {
                                    rules.push(r.selectorText);
                                }
                            }
                        } catch (e) {}
                    }
                    return rules;
                })()
            """)
            print(f":has() rules found in stylesheets: {has_selector_test}")

            # スクロール進捗テスト
            print("\n--- [追加] スクロール進捗バー動作確認 ---")
            await cdp_call(ws, "Runtime.evaluate", {
                "expression": "window.scrollTo({top: 2000, behavior: 'instant'});"
            })
            await asyncio.sleep(0.3)
            progress_transform = await eval_js(ws, """
                (() => {
                    const el = document.querySelector('.scroll-progress');
                    return getComputedStyle(el).transform;
                })()
            """)
            print(f"scroll 2000px 時の .scroll-progress transform: {progress_transform}")

            # ページ全体の高さ
            doc_height = await eval_js(ws, "document.documentElement.scrollHeight")
            print(f"document scrollHeight: {doc_height}")

            print("\n" + "=" * 60)
            print("検証完了")
            print("=" * 60)
    finally:
        requests.get(f"{CDP_URL}/json/close/{tab_id}")


if __name__ == "__main__":
    asyncio.run(main())
