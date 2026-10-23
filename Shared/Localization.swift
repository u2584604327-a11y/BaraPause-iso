import Foundation

enum TextKey {
    static func label(_ key: String, lang: String) -> String {
        let zh: [String: String] = [
            "home":"首页", "focus":"专注", "apps":"受限 App", "search":"快捷搜索",
            "settings":"设置", "authorize":"申请屏幕使用时间授权",
            "choose":"选择需要提醒的 App / 网站", "enable":"开启每日限额",
            "disable":"停止系统限额", "minutes":"分钟", "shield":"系统限制",
            "local":"所有内容都保存在本机", "theme":"外观模式", "language":"语言",
            "light":"浅色", "dark":"深色", "eye":"护眼", "system":"跟随系统",
            "focusStart":"开始专注", "focusStop":"结束专注", "active":"剩余专注",
            "noFocus":"尚未开始专注", "backup":"导出设置", "restore":"导入设置",
            "quickHint":"搜索关键词", "openWeb":"使用浏览器搜索",
            "openLink":"打开 HTTPS 内容链接", "history":"最近搜索",
            "noPermission":"需要先授权屏幕使用时间", "saved":"规则已保存",
            "unsupported":"当前系统暂不允许执行此操作", "shieldNote":"达到限额后显示 iOS 系统 Shield，不会弹出跨 App 浮窗。",
            "selected":"已选择内容", "privacy":"不上传 App 使用记录或关键词",
            "importError":"导入文件无效", "exportDone":"设置可在分享菜单中保存",
            "favorite":"收藏常用网址", "open":"打开", "cancel":"取消",
            "permission":"授权状态", "awaiting":"尚未授权", "approved":"已授权",
            "familyNotice":"Family Controls 权限需要真实 iPhone 和有效的 Apple 开发者授权。"
        ]
        let en: [String:String] = [
            "home":"Home","focus":"Focus","apps":"Limited Apps","search":"Quick Search",
            "settings":"Settings","authorize":"Authorize Screen Time",
            "choose":"Choose apps and websites","enable":"Enable daily limit",
            "disable":"Stop daily limit","minutes":"min","shield":"System Shield",
            "local":"Stored on your device","theme":"Appearance","language":"Language",
            "light":"Light","dark":"Dark","eye":"Eye comfort","system":"System",
            "focusStart":"Start focus","focusStop":"End focus","active":"Focus remaining",
            "noFocus":"No active focus","backup":"Export settings","restore":"Import settings",
            "quickHint":"Search keywords","openWeb":"Search in browser",
            "openLink":"Open HTTPS content link","history":"Recent searches",
            "noPermission":"Authorize Screen Time first","saved":"Rules saved",
            "unsupported":"Not supported on this device",
            "shieldNote":"The iOS system Shield appears at the limit. Cross-app overlays are not supported.",
            "selected":"Selected content","privacy":"No usage data or searches are uploaded",
            "importError":"Invalid backup file","exportDone":"Save these settings using the share sheet",
            "favorite":"Favorite website","open":"Open","cancel":"Cancel",
            "permission":"Authorization","awaiting":"Not authorized","approved":"Authorized",
            "familyNotice":"Family Controls requires a physical device and valid Apple entitlements."
        ]
        let tw: [String:String] = [
            "home":"首頁","focus":"專注","apps":"受限 App","search":"快速搜尋",
            "settings":"設定","authorize":"授權螢幕使用時間","choose":"選擇 App／網站",
            "enable":"啟用每日上限","disable":"停止每日上限","language":"語言",
            "light":"淺色","dark":"深色","eye":"護眼","system":"跟隨系統",
            "focusStart":"開始專注","focusStop":"結束專注","backup":"匯出設定",
            "restore":"匯入設定","quickHint":"搜尋關鍵字","openWeb":"瀏覽器搜尋",
            "history":"最近搜尋","open":"開啟","minutes":"分鐘","shield":"系統限制"
        ]
        let ja: [String:String] = [
            "home":"ホーム","focus":"集中","apps":"制限アプリ","search":"クイック検索",
            "settings":"設定","authorize":"スクリーンタイムを許可","choose":"アプリを選択",
            "enable":"一日の制限を有効化","disable":"制限を停止","language":"言語",
            "light":"ライト","dark":"ダーク","eye":"目に優しい","system":"システム",
            "focusStart":"集中開始","focusStop":"集中終了","backup":"設定を書き出し",
            "restore":"設定を読み込み","quickHint":"検索キーワード","openWeb":"ブラウザで検索",
            "history":"最近の検索","open":"開く","minutes":"分","shield":"システム制限"
        ]
        let base=en[key] ?? key
        switch lang {
        case "zh-Hans": return zh[key] ?? base
        case "zh-Hant": return tw[key] ?? zh[key] ?? base
        case "ja": return ja[key] ?? base
        default: return base
        }
    }
}
