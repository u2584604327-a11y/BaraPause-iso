# BaraPause iOS · 持续监控与真机验收规范

状态：**源码候选**。没有 macOS Xcode 编译报告、有效的签名 IPA 或 iPhone 真机通过记录，不得标记 RELEASE_READY。

## Apple API 实际边界

- Screen Time 任务由 `DeviceActivityCenter` 登记，关闭 BaraPause 界面通常不等于停止任务。
- 授权撤销、系统限制、应用删除、配置变更或操作系统异常都可能中断监控；**不保证后台永久运行**。
- 回调 `intervalDidStart` / `intervalDidEnd` 在设备使用时调用；不是精确的午夜定时器。
- 每日监测区间 00:00–23:59，系统可能发生跨天触发延迟；由真实 iPhone 验收。
- 重新登记使用 `includesPastActivity:true`，今天此前累计使用可能立即触发限制，而不是每次重开都重新获得额度。
- 系统 Shield 只支持 Apple 配置的静态图标、文案和按钮；自定义连续动画仅在 BaraPause 本身页面显示。

## 编译门禁（macOS 必须执行）

```bash
brew install xcodegen cairo
python3 -m venv .venv
. .venv/bin/activate
python -m pip install cairosvg
python Scripts/build_icons.py
python Scripts/static_audit.py
find App Shared Widget Monitor Shield ShieldAction Share -name '*.swift' -print0 | while IFS= read -r -d '' f; do
  xcrun swiftc -frontend -parse "$f" || exit 1
done
xcodegen generate --spec project.yml
xcodebuild -project BaraPause.xcodeproj -scheme BaraPause -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

以上成功仅表示模拟器构建，**不代表 Screen Time 真机通过**。须单独配置 Apple Developer Team、主 App + Monitor + Shield + ShieldAction 的 Family Controls entitlement，以及 App Group；分享和 Widget 扩展也要拥有相同 App Group。

## 真机验收用例

| 编号 | 操作 | 通过条件 |
|---|---|---|
| I01 | 开启 Family Controls 后选 1 个测试 App，设置短限额 | Apple 显示授权状态，系统活动登记真实存在 |
| I02 | 选择一个尚未超限的 App，退出 BaraPause，继续使用 | 达阈值后由 iOS 显示 Shield，不依赖 BaraPause 常驻 |
| I03 | 点击 Shield 的「继续休息」 | 由系统关闭受限 App，不解除限制 |
| I04 | 强制关闭 BaraPause 主程序，重新打开 | 不误报监控关闭；查询 `center.activities` 返回有效登记 |
| I05 | 重启 iPhone 后再次使用受限 App | 查询系统登记；仍生效则 PASS，失效必须提示异常而非虚报 |
| I06 | 修改受限 App 后重新登记 | 旧任务停止，旧回调不按新 token 生效 |
| I07 | 将每日限额设为较小值、当日已超限再重新登记 | 允许立即 Shield，诊断记录正确；不虚报新额度 |
| I08 | 设备跨越 23:59、00:00 并重新使用 | 旧限制按系统周期释放，新周期重新计算；回调可能延迟 |
| I09 | 在系统设置撤销 Screen Time 授权 | 页面回前台刷新为不可用/待恢复，不虚报已启用 |
| I10 | App Group 配置失效 | 拒绝开启监控，显示错误 |
| I11 | 导入新备份导致限额变化 | 提示设置尚未重登记；旧系统任务不悄然改变 |
| I12 | 系统返回 startMonitoring 错误 | 不保留虚假的已启用标记，不留下旧 Shield |
| I13 | 打开/关闭自定义水豚、Widget、语言切换 | 不影响已登记的 Screen Time 任务 |
| I14 | 后台停留数小时、充电与省电模式切换 | 无无障碍、私有 API 或后台轮询依赖；异常必须留证据 |

### 证据

每项至少保存：iOS 版本、设备型号、系统设置截图、BaraPause「持续监控」诊断（已脱敏）、Shield 触发画面、Xcode 设备日志中对应回调。明确区分 `PASS`、`FAIL`、`BLOCKED_ENTITLEMENT` 和 `NOT_TESTED`。

### 熔断

- 未得到 Family Controls entitlement：不得以模拟器结果证明真机屏幕时间有效。
- 监控状态与 DeviceActivityCenter 不一致：先停止旧任务并人工重新登记，不自动静默恢复。
- Shield 未解除、类别错误屏蔽或跨天持续屏蔽：冻结发行版本，保留调试日志，暂停增加功能。
- 没有成功 Xcode 编译、签名和真机安装：**不交付虚构 IPA**。
