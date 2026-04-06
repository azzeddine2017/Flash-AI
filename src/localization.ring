class Localization
    cLang = "en"
    
    aStrings = [
        ["en", [
            ["welcome", "Welcome! I'm FLASH AI. How can I help you today?"],
            ["help_hint", "Enter=Send  |  ls/files=List files  |  read <file>  |  help  |  exit"],
            ["chat_history", "--- Conversation History ---"],
            ["thinking", "Thinking"],
            ["reasoning", "REASONING:"],
            ["error", "✘ Error: "],
            ["success", "✔ "],
            ["security_alert", "SECURITY ALERT: "],
            ["auth_prompt", "Do you want to authorize this action? (y-yes / n-no / a-always): "],
            ["sensitive_action", "Sensitive Action Requested              ║"]
        ]],
        ["ar", [
            ["welcome", "مرحباً! أنا فلاش للذكاء الاصطناعي. كيف يمكنني مساعدتك اليوم؟"],
            ["help_hint", "Enter=إرسال  |  ls/files=عرض الملفات  |  read <file>  |  help  |  exit"],
            ["chat_history", "--- سجل المحادثة ---"],
            ["thinking", "يُفكر"],
            ["reasoning", "التحليل والاستنتاج:"],
            ["error", "✘ خطأ: "],
            ["success", "✔ "],
            ["security_alert", "تنبيه أمني: "],
            ["auth_prompt", "هل توافق على هذا الإجراء؟ (y-نعم / n-لا / a-دائماً): "],
            ["sensitive_action", "إجراء حساس مطلوب                        ║"]
        ]]
    ]
    
    func setLang l
        cLang = lower(l)
    
    func getString sKey
        for lang in aStrings
            if lang[1] = cLang
                for item in lang[2]
                    if item[1] = sKey
                        return item[2]
                    ok
                next
            ok
        next
        return sKey
