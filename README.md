# BaraPause iOS — 原生 SwiftUI 版

与 Android [BaraPause](https://github.com/u2584604327-a11y/sbara) 分开维护。iOS 版采用 **SwiftUI + FamilyControls + DeviceActivity + ManagedSettings + WidgetKit**，而不是把 APK 转成 IPA。

## 已实现的源码架构

- 自定义水豚主题主页、可调专注计时、简体/繁体中文、英语和日语、深色/护眼主题
- 系统 Screen Time 授权与官方 FamilyActivityPicker；用户选择 App，再设置每日阈值
- DeviceActivityMonitor Extension 在阈值触发时对对应 App 设置屏幕时间 Shield
- ShieldConfiguration Extension 自定义卡片文案与配色（iOS 不允许任意跨 App 浮窗或连续动画覆盖）
- WidgetKit 小/中组件，跳转至搜索、专注页面
- 本地 JSON 设置导出/导入（不导出不透明 App Tokens）；HTTPS 内容链接、分享入口
- PhotosPicker 自定义水豚提醒图片与应用内呼吸动画（Shield 的实际图片显示受系统扩展限制）

## 开始构建

1. Mac 安装 **Xcode 16+**、XcodeGen、Python 3 与 CairoSVG。
2. 运行 `python3 Scripts/build_icons.py`，创建 AppIcon/水豚资源。
3. 运行 `xcodegen generate`，用 Xcode 打开 `BaraPause.xcodeproj`。
4. 配置你的 Apple Developer Team，并将示例包名/ App Group 换成你有权注册的标识。
5. 在 Apple Developer 网站为**主 App、Device Activity Monitor、Shield Configuration 三个 Bundle ID**分别申请 Family Controls 分发 entitlement；配置 App Groups。
6. 先在 Xcode 使用模拟器构建 UI，再在真实 iPhone 上授权 Screen Time、测试每日阈值和 Shield。模拟器不等于真实 Screen Time 验收。

只需校验编译：Actions → `iOS simulator validation` → Run workflow（手动执行，避免耗尽 Actions macOS 配额）。

## 能力边界

iOS 不允许第三方常驻跨 App 悬浮窗、无授权读取所有已安装 App、任意调用其他 App 私有搜索页。BaraPause 只使用 Apple 官方授权和用户确认的 URL/Universal Links。专注计时是本应用内计时，不等同于已经授权且生效的系统限制。

**目前没有经真实 iPhone 验证的 IPA，也没有未经你授权的自动签名或发布。**
