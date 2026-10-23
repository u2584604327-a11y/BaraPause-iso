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


## V1.1 多存档与系统持续性（候选）

- 进入「受限 App」→「多存档 · 快速切换」，最多保存 **8 套本地档位**。
- 每套独立保存 App/类别/网站的匿名 Tokens、每日限额、语言与主题；允许创建空档、复制、重命名、删除、明确确认切换。
- 切换前保存旧档；若系统原先正监测，会停用旧规则并为新档重新申请 DeviceActivity 计划；空档不会偷偷保留旧 App 的 Shield。
- 返回受限 App 页面时，检查 `DeviceActivityCenter.activities` 和授权；若检测到计划中断，显示**手动恢复系统监控**，不能伪造“后台始终在线”。
- 在选择器关闭或离开页面时，保存未提交的受限 App 选择草稿。
- 当系统触发阈值时，由 DeviceActivityMonitor Extension 执行限制，无需 App 自己持续在后台运行。
- 跨设备 JSON 配置备份**不包含**系统匿名 Tokens；iOS 不保证匿名 Tokens 跨设备可用。

## 构建门禁（严禁虚报 IPA）

本仓库在 GitHub Actions 有一个**手动** macOS Simulator 工作流：`iOS simulator validation`。它生成资源、校验 plist/entitlement、解析 Swift 并执行 Xcode Simulator 编译，**不签名、不生成 IPA**。本地开发者需要在 Xcode 中完成 Family Controls entitlement、App Group、Provisioning Profile 的开发者证书配置后真机验收。

提交前的最低真机用例：授权→添加目标 App→限额触发 Shield；杀掉主 App 后系统监控继续（扩展独立执行）；撤销 Screen Time 权限显示失效；多档切换后旧 App 不再被原档限制；重启后档位、剩余专注时长和已选规则保留。不能以模拟器或静态检查替代这些验收。

本阶段仍为源代码候选，**没有任何可验证已签名 IPA**。
