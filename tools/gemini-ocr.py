#!/usr/bin/env python3
"""
Gemini OCR - 日本語画像文字起こしツール
Usage: python3 gemini-ocr.py <image_path> [--url <url>]
       python3 gemini-ocr.py --url "https://example.com" (Webページテキスト抽出)
"""

import sys
import os
import base64
import mimetypes
import argparse
from google import genai

def ocr_image(image_path: str) -> str:
    """画像ファイルから日本語テキストを抽出"""
    client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY"))

    mime_type, _ = mimetypes.guess_type(image_path)
    if not mime_type:
        mime_type = "image/png"

    with open(image_path, "rb") as f:
        image_data = base64.standard_b64encode(f.read()).decode("utf-8")

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            {
                "parts": [
                    {"inline_data": {"mime_type": mime_type, "data": image_data}},
                    {"text": "この画像に含まれるテキストを全て正確に文字起こししてください。レイアウトや改行もできるだけ再現してください。テキスト以外の説明は不要です。"},
                ]
            }
        ],
    )
    return response.text


def ocr_url(url: str) -> str:
    """WebページURLからテキストを抽出"""
    client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY"))

    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            {
                "parts": [
                    {"text": f"以下のURLのWebページにアクセスし、ページに含まれるテキストコンテンツを全て正確に抽出してください。HTMLタグは除外し、人間が読める形式で出力してください。\n\nURL: {url}"},
                ]
            }
        ],
    )
    return response.text


def main():
    parser = argparse.ArgumentParser(description="Gemini OCR - 日本語文字起こし")
    parser.add_argument("image", nargs="?", help="画像ファイルのパス")
    parser.add_argument("--url", help="WebページのURL")
    args = parser.parse_args()

    if not args.image and not args.url:
        parser.print_help()
        sys.exit(1)

    if args.url:
        result = ocr_url(args.url)
    elif args.image:
        if not os.path.exists(args.image):
            print(f"Error: ファイルが見つかりません: {args.image}", file=sys.stderr)
            sys.exit(1)
        result = ocr_image(args.image)

    print(result)


if __name__ == "__main__":
    main()
