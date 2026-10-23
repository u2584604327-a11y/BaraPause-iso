import Foundation

/// Shared App Group storage. Neither app activity history nor opaque tokens leave the device.
enum BaraStore {
    static let group = "group.de.claua.barapause"
    static let defaults = UserDefaults(suiteName: group)

    static var focusDeadline: Date? {
        get {
            let t = defaults?.double(forKey: "focusUntil") ?? 0
            return t > 0 ? Date(timeIntervalSince1970: t) : nil
        }
        set {
            defaults?.set(newValue?.timeIntervalSince1970 ?? 0, forKey: "focusUntil")
        }
    }

    static var dailyLimitMinutes: Int {
        get {
            let n = defaults?.integer(forKey: "dailyMinutes") ?? 20
            return n > 0 ? min(240, n) : 20
        }
        set { defaults?.set(max(1, min(240, newValue)), forKey: "dailyMinutes") }
    }

    static var selectionData: Data? {
        get { defaults?.data(forKey: "familySelection") }
        set { defaults?.set(newValue, forKey: "familySelection") }
    }

    static var reminderStyle: String {
        get { defaults?.string(forKey: "reminderStyle") ?? "breathe" }
        set { defaults?.set(newValue, forKey: "reminderStyle") }
    }

    static var language: String {
        get { defaults?.string(forKey: "language") ?? "system" }
        set { defaults?.set(newValue, forKey: "language") }
    }

    static var appearance: String {
        get { defaults?.string(forKey: "appearance") ?? "system" }
        set { defaults?.set(newValue, forKey: "appearance") }
    }
}

enum BaraStrings {
    // Small built-in language set, no network or remote localization dependency.
    private static let words: [String: [String: String]] = [
        "zh-Hans": [
            "home":"首页", "focus":"专注计时", "limits":"应用限额", "quick":"快捷搜索",
            "settings":"偏好设置", "choose":"选择受限应用", "authorize":"授权屏幕使用时间",
            "begin":"开始专注", "end":"结束本轮", "notRunning":"尚未开始专注",
            "shield":"达到限额后使用 iOS 系统提醒页面", "daily":"每日使用上限",
            "minutes":"分钟", "saveRule":"启动每日监测", "stopRule":"停止每日监测",
            "widget":"桌面组件", "searchHint":"输入搜索关键词", "open":"用系统打开",
            "backup":"配置备份", "export":"导出配置", "import":"导入配置",
            "look":"主题", "language":"语言", "motion":"水豚动画",
            "status":"状态", "active":"正在监测", "inactive":"未启用",
            "limitations":"iOS 不允许在其他 App 上方显示第三方常驻浮窗。"
        ],
        "zh-Hant": [
            "home":"首頁", "focus":"專注計時", "limits":"應用上限", "quick":"快速搜尋",
            "settings":"偏好設定", "choose":"選擇受限 App", "authorize":"授權螢幕使用時間",
            "begin":"開始專注", "end":"結束專注", "notRunning":"尚未開始專注",
            "shield":"達到上限時顯示 iOS 系統提醒畫面", "daily":"每日使用上限",
            "minutes":"分鐘", "saveRule":"啟用每日監測", "stopRule":"停止每日監測",
            "widget":"桌面小工具", "searchHint":"輸入搜尋關鍵字", "open":"使用系統開啟",
            "backup":"備份設定", "export":"匯出設定", "import":"匯入設定",
            "look":"主題", "language":"語言", "motion":"水豚動畫",
            "status":"狀態", "active":"監測中", "inactive":"未啟用",
            "limitations":"iOS 不允許第三方跨 App 常駐懸浮窗。"
        ],
        "en": [
            "home":"Home", "focus":"Focus timer", "limits":"App limits", "quick":"Quick search",
            "settings":"Preferences", "choose":"Choose limited apps", "authorize":"Authorize Screen Time",
            "begin":"Start focus", "end":"End session", "notRunning":"No focus session running",
            "shield":"Show the system Screen Time shield at the limit", "daily":"Daily usage limit",
            "minutes":"minutes", "saveRule":"Start daily monitoring", "stopRule":"Stop monitoring",
            "widget":"Home widget", "searchHint":"Enter search keywords", "open":"Open with iOS",
            "backup":"Settings backup", "export":"Export settings", "import":"Import settings",
            "look":"Appearance", "language":"Language", "motion":"Capybara animation",
            "status":"Status", "active":"Monitoring", "inactive":"Inactive",
            "limitations":"iOS does not allow an always-on overlay above other apps."
        ],
        "ja": [
            "home":"ホーム", "focus":"集中タイマー", "limits":"アプリ制限", "quick":"クイック検索",
            "settings":"設定", "choose":"制限アプリを選択", "authorize":"スクリーンタイムを許可",
            "begin":"集中開始", "end":"終了", "notRunning":"集中していません",
            "shield":"時間制限後に iOS シールドを表示", "daily":"毎日の使用上限",
            "minutes":"分", "saveRule":"毎日の監視を開始", "stopRule":"監視停止",
            "widget":"ウィジェット", "searchHint":"検索ワード", "open":"システムで開く",
            "backup":"設定のバックアップ", "export":"書き出し", "import":"読み込み",
            "look":"テーマ", "language":"言語", "motion":"カピバラの動き",
            "status":"状態", "active":"監視中", "inactive":"停止中",
            "limitations":"iOS は他のアプリ上に常駐するオーバーレイを許可しません。"
        ]
    ]

    static func text(_ key: String) -> String {
        let saved = BaraStore.language
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code: String = saved == "system"
          ? (preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") ? "zh-Hant" :
             preferred.hasPrefix("zh") ? "zh-Hans" :
             preferred.hasPrefix("ja") ? "ja" : "en")
          : saved
        return words[code]?[key] ?? words["en"]?[key] ?? key
    }
}
