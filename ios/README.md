# O'Clock · iOS widget

A real Home Screen widget for O'Clock, written in SwiftUI + WidgetKit (iOS 17+).

- **Sticker** and **Hand-drawn** styles. Touch and hold the widget → Edit Widget → Style.
- Words on the pointers are pressed in with two inner shadows (the same engraving as the web demo).
- One timeline entry per minute: the hands move, and a task's slice opens on time.
- The app is a preview: scrub through the day and switch styles.

The schedule is the same demo day as the web version (`Shared/OClockCore.swift → Schedule.tasks`).

## 装到自己的 iPhone 上

1. 用 Xcode（16 或更新）打开 `OClock.xcodeproj`。
2. 左侧点最上面的蓝色 **OClock** 项目 → **Signing & Capabilities**：两个 target（OClock、OClockWidgetExtension）的 **Team** 都选你的 Apple ID（Personal Team 就行）。
   如果提示 bundle identifier 已被占用，把 `com.shuyiyuan.oclock` 改成别的，比如 `com.你的名字.oclock`，widget 那个对应改成 `….oclock.widget`。
3. 手机用线连上 Mac，顶部选你的 iPhone，点 ▶︎ 运行。
   第一次装：手机上 **设置 → 通用 → VPN 与设备管理** 里信任你的开发者证书；**设置 → 隐私与安全性 → 开发者模式** 打开。
4. 回到主屏幕，长按空白处 → 编辑 → 添加小组件 → 找到 **O'Clock**。

不连手机也能看：打开 `OClockWidget/OClockWidget.swift`，右侧的 Canvas 预览里能直接看到小组件在不同时间的样子。
