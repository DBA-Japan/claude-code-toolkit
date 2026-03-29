# マイクロインタラクションガイド

ボタン、リンク、カード、カーソルのプレミアムなインタラクション実装コード集。

---

## ボタン

### 磁気ボタン（Magnetic）
マウス座標とボタン中心の距離を計算し、GSAP で transform。

```js
document.querySelectorAll('.magnetic-btn').forEach(btn => {
  btn.addEventListener('mousemove', (e) => {
    const rect = btn.getBoundingClientRect();
    const x = e.clientX - rect.left - rect.width / 2;
    const y = e.clientY - rect.top - rect.height / 2;
    gsap.to(btn, { x: x * 0.4, y: y * 0.4, duration: 0.3 });
  });
  btn.addEventListener('mouseleave', () => {
    gsap.to(btn, { x: 0, y: 0, duration: 0.5, ease: 'elastic.out(1, 0.3)' });
  });
});
```

### リップル（Material Design 風）
クリック地点から円形波紋。

```js
btn.addEventListener('click', (e) => {
  const ripple = document.createElement('span');
  ripple.className = 'ripple';
  ripple.style.left = `${e.offsetX}px`;
  ripple.style.top = `${e.offsetY}px`;
  btn.appendChild(ripple);
  ripple.addEventListener('animationend', () => ripple.remove());
});
```

```css
.ripple {
  position: absolute; border-radius: 50%;
  width: 10px; height: 10px;
  background: rgba(255,255,255,0.4);
  transform: scale(0);
  animation: ripple-expand 0.6s ease-out;
  pointer-events: none;
}
@keyframes ripple-expand { to { transform: scale(40); opacity: 0; } }
```

---

## テキスト / リンク

### アンダーライン展開

```css
a { position: relative; }
a::after {
  content: '';
  position: absolute; bottom: -2px; left: 0;
  width: 100%; height: 2px;
  background: currentColor;
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.3s ease;
}
a:hover::after { transform: scaleX(1); }
```

### 意図的ホバー（transition-delay）

```css
a:hover::after { transform: scaleX(1); transition-delay: 0.15s; }
a::after { transform: scaleX(0); transform-origin: 100% 50%; transition: transform 0.2s; }
```

`transition-delay: 0.15s` で「意図的に触った」感。

### グラデーションボーダー回転

```css
@property --angle { syntax: '<angle>'; inherits: true; initial-value: 0deg; }
.card {
  border-image: conic-gradient(from var(--angle), #ff0080, #00d4aa, #ff0080) 1;
  animation: spin 4s linear infinite;
}
@keyframes spin { to { --angle: 360deg; } }
```

### 光るボーダー（offset-path）

```css
.glow::after {
  offset-path: rect(0 100% 100% 0 round var(--radius));
  animation: loop 3s linear infinite;
}
```

---

## カーソル

### mouse-follower (Cuberto)
GSAP 依存。リンク/CTA 上でサイズ変化。

```html
<script src="https://unpkg.com/mouse-follower@latest/dist/mouse-follower.min.js"></script>
<link rel="stylesheet" href="https://unpkg.com/mouse-follower@latest/dist/mouse-follower.min.css">
```

```js
const cursor = new MouseFollower();
```

PC 専用: `@media (hover: hover)` で制御。

### MagicMouse.js
GSAP 不要の軽量代替。422★。

---

## 画像

### 液体歪み（hover-effect）

```html
<script src="https://cdn.jsdelivr.net/npm/hover-effect"></script>
```

```js
new hoverEffect({
  parent: document.querySelector('.distortion'),
  image1: 'img1.jpg',
  image2: 'img2.jpg',
  displacementImage: 'displacement.png',
  intensity: 0.3
});
```

### カーテン開き（clip-path reveal）

```css
.reveal {
  clip-path: inset(100% 0 0 0);
  transition: clip-path 0.8s ease;
}
.reveal.visible { clip-path: inset(0); }
```

---

## パフォーマンスルール

| ルール | 理由 |
|--------|------|
| `transform` + `opacity` のみ | reflow 回避 |
| 200-500ms のデュレーション | 遅すぎない |
| `@media (prefers-reduced-motion: reduce)` で無効化 | アクセシビリティ |
| モバイル: hover → タップ/フォーカス | タッチデバイス対応 |
