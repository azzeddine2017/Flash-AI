/*
==============================================================================
    FLASH AI - Premium Graphical UI (RingQt)
    Version 2.0 - With Token Counting, Tool Display and Enhanced Sidebar
    Refactored to Class-based structure for better scoping
==============================================================================
*/
load "guiLib.ring"
load "src/loadFiles.ring"

# Global handle for callbacks
oFlashGUI = null

func main
    oFlashGUI = new FlashGUI
    oFlashGUI.run()

class FlashGUI
    # Core Components
    oSmartAgent = new SmartAgent()
    oCoreAgent  = new CoreAgent()
    oApp = null
    oWin = null
    oHistory = null
    oInput = null
    oListSessions = null
    aSessionsFiles = []
    oTokenLabel = null
    oAuthCheck = null
    oSideTitle = null
    oTitleLabel = null
    oBtnClear = null
    oBtnDelete = null
    oBtnLang = null
    oStatusIndicator = null
    oSend = null
    oBtnSaveJSON = null
    oBtnSaveText = null
    oBtnSaveMD = null
    oBtnSave = null
    oModelLabel = null
    oProviderLabel = null

    # Constants & Config
    Qt_RightToLeft = 1
    Qt_LeftToRight = 0
    C_SIDEBAR_WIDTH = 280
    C_PRIMARY_COLOR = "#58a6ff"
    C_BG_DARK       = "#0d1117"
    C_BG_CARD       = "#161b22"
    C_SUCCESS_GREEN = "#238636"
    C_BORDER        = "#30363d"

    # Translations - Default to English
    C_LANG = "EN"
    T_TITLE    = "FLASH AI — Super Engineer"
    T_SESSIONS = "Session History"
    T_AUTH     = "Full Permissions"
    T_NEW      = "New Session"
    T_DELETE   = "Delete Session"
    T_SAVE_JSON = "JSON"
    T_SAVE_TEXT = "Text"
    T_SAVE_MD   = "MD"
    T_SAVE      = "Save Chat"
    T_PLACE    = "Type your request... (Enter to Send, Shift+Enter for newline)"
    T_EXEC     = "Execute"
    T_ONLINE   = "● Online"
    T_YOU      = "You"
    T_AGENT    = "FLASH AI"
    T_TOKENS   = "Tokens: "
    T_SEC_TITLE = "Security Alert"
    T_SEC_MSG   = "The AI is requesting to perform a sensitive action. Do you authorize this?"

    func run
        oCoreAgent.setSmartAgent(oSmartAgent)
        oCoreAgent.setFrontend(new GUIManager)
        
        oApp = new qApp
        oWin = new qMainWindow() 
        oWin.setwindowtitle(T_TITLE)
        oWin.resize(1200, 700)

        oWin.setStyleSheet("
            QMainWindow { background-color: " + C_BG_DARK + "; }
            QWidget { color: #e6edf3; font-family: 'Segoe UI', Roboto, Arial; font-size: 11pt; }
            #Sidebar { background-color: #161b22; border-right: 1px solid #30363d; min-width: 250px; }
            #ChatArea { background-color: #0d1117; }
            #History { 
                background-color: #0d1117; 
                border: none; 
                padding: 10px; 
                font-size: 12pt; 
                line-height: 1.5;
            }
            #InputBox { 
                background-color: #161b22; 
                border: 1px solid #30363d; 
                border-radius: 12px; 
                padding: 15px; 
                color: #e6edf3;
                font-size: 11pt;
            }
            #InputBox:focus { border: 1px solid #58a6ff; }
            QPushButton { 
                background-color: #21262d; 
                border: 1px solid #30363d; 
                border-radius: 8px; 
                padding: 8px 15px; 
                font-weight: bold;
            }
            QPushButton:hover { background-color: #30363d; border-color: #8b949e; }
            #BtnExec { background-color: #238636; border-color: #2ea043; color: white; }
            #BtnExec:hover { background-color: #2ea043; }
            #BtnNew { background-color: #1f6feb; border-color: #388bfd; color: white; }
            #BtnNew:hover { background-color: #388bfd; }
            QListWidget { background-color: #0d1117; border: none; font-size: 10pt; }
            QListWidget::item { padding: 12px; border-bottom: 1px solid #21262d; border-radius: 6px; margin: 2px; }
            QListWidget::item:selected { background-color: #1f6feb; color: white; }
            QScrollBar:vertical { border: none; background: #0d1117; width: 10px; margin: 0; }
            QScrollBar::handle:vertical { background: #30363d; min-height: 20px; border-radius: 5px; }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }
        ")

        oWin.setLayoutDirection(Qt_LeftToRight)

        oCentral = new qWidget()
        oCentralLayout = new qHBoxLayout()
        oCentral.setLayout(oCentralLayout)
        oWin.setCentralWidget(oCentral)

        # --- Sidebar ---
        oSidebar = new qFrame(oWin, 0)
        oSidebar.setObjectName("Sidebar")
        oSidebar.setFixedWidth(C_SIDEBAR_WIDTH)
        oSideLayout = new qVBoxLayout()
        
        oSideTitle = new qLabel(oSidebar)
        oSideTitle.setText(T_SESSIONS)
        oSideTitle.setStyleSheet("font-size: 14pt; margin: 15px; font-weight: bold; color: " + C_PRIMARY_COLOR)
        oSideLayout.addWidget(oSideTitle)

        oListSessions = new qListWidget(oSidebar)
        oListSessions.setMinimumHeight(400)
        oListSessions.setObjectName("ListSessions")
        oListSessions.setitemClickedEvent("oFlashGUI.loadSelectedSession()")
        oListSessions.setitemDoubleClickedEvent("oFlashGUI.loadSelectedSession()")
        oSideLayout.addWidget(oListSessions)
        
        # Export Buttons
        oSaveRow = new qHBoxLayout()
        oBtnSaveJSON = new qPushButton(oSidebar)
        oBtnSaveJSON.setObjectName("SideBtn")
        oBtnSaveJSON.setText(T_SAVE_JSON)
        oBtnSaveJSON.setClickEvent("oFlashGUI.saveSessionJSON()")
        
        oBtnSaveText = new qPushButton(oSidebar)
        oBtnSaveText.setObjectName("SideBtn")
        oBtnSaveText.setText(T_SAVE_TEXT)
        oBtnSaveText.setClickEvent("oFlashGUI.saveSessionText()")
        
        oBtnSaveMD = new qPushButton(oSidebar)
        oBtnSaveMD.setObjectName("SideBtn")
        oBtnSaveMD.setText(T_SAVE_MD)
        oBtnSaveMD.setClickEvent("oFlashGUI.saveSessionMD()")
        
        oSaveRow.addWidget(oBtnSaveJSON)
        oSaveRow.addWidget(oBtnSaveText)
        oSaveRow.addWidget(oBtnSaveMD)
        oSideLayout.addLayout(oSaveRow)

        oBtnDelete = new qPushButton(oSidebar)
        oBtnDelete.setObjectName("DelBtn")
        oBtnDelete.setText(T_DELETE)
        oBtnDelete.setClickEvent("oFlashGUI.deleteSelectedSession()")
        oSideLayout.addWidget(oBtnDelete)

        oSideLayout.addStretch(1)

        oAuthCheck = new qCheckBox(oSidebar)
        oAuthCheck.setText(T_AUTH)
        oAuthCheck.setStyleSheet("margin: 10px;")
        oAuthCheck.setstatechangedEvent("oFlashGUI.toggleAuth()")
        oSideLayout.addWidget(oAuthCheck)

        oBtnLang = new qPushButton(oSidebar)
        oBtnLang.setText("العربية")
        oBtnLang.setClickEvent("oFlashGUI.toggleLanguage()")
        oSideLayout.addWidget(oBtnLang)

        oBtnClear = new qPushButton(oSidebar)
        oBtnClear.setObjectName("BtnNew")
        oBtnClear.setText(T_NEW)
        oBtnClear.setClickEvent("oFlashGUI.clearSession()")
        oSideLayout.addWidget(oBtnClear)

        oSidebar.setLayout(oSideLayout)
        oCentralLayout.addWidget(oSidebar)

        # --- Chat Area ---
        oChatArea = new qWidget()
        oChatArea.setObjectName("ChatArea")
        oChatLayout = new qVBoxLayout()
        oChatArea.setLayout(oChatLayout)

        # Top Bar in Chat
        oTopBar = new qHBoxLayout()
        oTitleLabel = new qLabel(oChatArea)
        oTitleLabel.setText(T_TITLE) 
        oTitleLabel.setStyleSheet("font-size: 18pt; font-weight: bold; color: " + C_PRIMARY_COLOR)
        
        oStatusIndicator = new qLabel(oChatArea)
        oStatusIndicator.setText(T_ONLINE) 
        oStatusIndicator.setStyleSheet("color: #3fb950; font-weight: bold;")
        
        oTokenLabel = new qLabel(oChatArea)
        oTokenLabel.setText(T_TOKENS + "0") 
        oTokenLabel.setStyleSheet("color: #8b949e;")
        
        oTopBar.addWidget(oTitleLabel)
        oTopBar.addStretch(1)
        oTopBar.addWidget(oStatusIndicator)
        oTopBar.addSpacing(20)
        oTopBar.addWidget(oTokenLabel)
        oChatLayout.addLayout(oTopBar)

        # History
        oHistory = new qTextEdit(oChatArea)
        oHistory.setObjectName("History")
        oHistory.setReadOnly(true)
        oHistory.setHtml("<div style='color:#8b949e; text-align:center; margin-top:100px; font-family:Consolas;'>Welcome to FLASH AI v2.5<br>Sovereign Intelligence Active</div>")
        oChatLayout.addWidget(oHistory)

        oInputRow = new qHBoxLayout()
        oInput = new qTextEdit(oChatArea)
        oInput.setObjectName("InputBox") 
        oInput.setPlaceholderText(T_PLACE) 
        oInput.setMaximumHeight(100)
        
        oSend = new qPushButton(oChatArea)
        oSend.setObjectName("BtnExec")
        oSend.setText(T_EXEC) 
        oSend.setClickEvent("oFlashGUI.processInputText()") 
        oSend.setMinimumHeight(60)
        
        oInputRow.addWidget(oInput)
        oInputRow.addWidget(oSend)
        oChatLayout.addLayout(oInputRow)

        # Heavy-Duty Enter-to-Send Shortcut (Directly attached to Input)
        oEnterShortcut = new qShortcut(oInput) {
            setKey(new qKeySequence("Return"))
            setContext(1) # Qt_WidgetShortcut (Highest priority when input is focused)
            setactivatedEvent("oFlashGUI.processInputText()")
        }
        oEnterShortcut2 = new qShortcut(oInput) {
            setKey(new qKeySequence("Enter"))
            setContext(1) # Qt_WidgetShortcut
            setactivatedEvent("oFlashGUI.processInputText()")
        }
        oEnterShortcut3 = new qShortcut(oInput) {
            setKey(new qKeySequence("Ctrl+Return"))
            setactivatedEvent("oFlashGUI.processInputText()")
        }

        # Status Bar
        oStatusBar = new qHBoxLayout()
        oModelLabel = new qLabel(oChatArea)
        cMdl = oCoreAgent.oSmartAgent.oAIClient.cGeminiModel
        switch oCoreAgent.oSmartAgent.oAIClient.cCurrentProvider
            on "openai" cMdl = oCoreAgent.oSmartAgent.oAIClient.cOpenAIModel
            on "claude" cMdl = oCoreAgent.oSmartAgent.oAIClient.cClaudeModel
            on "openrouter" cMdl = oCoreAgent.oSmartAgent.oAIClient.cOpenRouterModel
        off
        oModelLabel.setText("Model: " + cMdl) 
        oModelLabel.setStyleSheet("color: #8b949e; font-size: 9pt; padding: 5px;")
        
        oProviderLabel = new qLabel(oChatArea)
        oProviderLabel.setText("Provider: " + oCoreAgent.oSmartAgent.oAIClient.cCurrentProvider) 
        oProviderLabel.setStyleSheet("color: #8b949e; font-size: 9pt; padding: 5px;")
        
        oStatusBar.addWidget(oModelLabel)
        oStatusBar.addStretch(1)
        oStatusBar.addWidget(oProviderLabel)
        oChatLayout.addLayout(oStatusBar)

        oCentralLayout.addWidget(oChatArea)
        oWin.show()
        
        refreshSessionsList()
        oApp.exec()

    func displayToolActionInternal cToolName, cDetails
        cHtml = "<div style='background-color:#161b22; border: 1px solid #30363d; border-radius:8px; padding:10px; margin:5px 20px; border-left: 4px solid #d19a66;'>" + 
               "<span style='color:#d19a66; font-family:monospace; font-weight:bold;'>◆ TOOL_CALL: " + upper(cToolName) + "</span>" +
               "<div style='color: #8b949e; font-size:10pt; font-family:Consolas; margin-top:4px;'>" + cDetails + "</div></div>"
        oHistory.append(cHtml)
        oHistory.verticalScrollBar().setValue(oHistory.verticalScrollBar().maximum())
        oApp.processEvents()

    func jsonEncodeRecursive(oVal) return jsonEncodeRecursive(oVal)
    func jsonEscape(cStr) return jsonEscape(cStr)

    func displayAIMessageInternal cMsg
        cAgentMsg = "<div style='height:15px;'></div>" +
                    "<table width='100%'><tr><td align='left'>" +
                    "<div style='background-color:#161b22; color:#e1e4e8; border: 1px solid #30363d; border-radius:18px 18px 18px 2px; padding:15px 22px; font-size:12pt; max-width:85%; shadow: 0 4px 6px rgba(0,0,0,0.3);'>" +
                    "<div style='margin-bottom:8px;'><span style='color:"+C_PRIMARY_COLOR+"; font-weight:bold; font-size:11pt;'>✦ " + upper(T_AGENT) + "</span></div>" +
                    "<div style='line-height:1.6;'>" + renderMarkdown(cMsg) + "</div></div>" +
                    "</td></tr></table>"
        oHistory.append(cAgentMsg)
        oHistory.verticalScrollBar().setValue(oHistory.verticalScrollBar().maximum())
        oApp.processEvents()

    func refreshSessionsList
        if isNULL(oListSessions) return ok
        oListSessions.clear()
        aSessionsFiles = []
        aSessions = oCoreAgent.oSmartAgent.getSavedSessions()
        aPreviews = oCoreAgent.oSmartAgent.getSessionsWithPreviews(aSessions)
        for oItem in aPreviews
            cFile = oItem[1][2]
            cPrv  = oItem[2][2]
            oListSessions.addItem(cPrv)
            Add(aSessionsFiles, cFile)
        next

    func processInputText
        cCmd = oInput.toPlainText()
        if trim(cCmd) = "" return ok
        
        cUserMsg = "<div style='height:15px;'></div>" +
                   "<table width='100%'><tr><td align='right'>" +
                   "<div style='background-color:#0969da; color:white; border-radius:18px 18px 2px 18px; padding:15px 22px; font-size:12pt; display:inline-block; max-width:80%;'>" +
                   "<div style='margin-bottom:8px; opacity:0.8; font-weight:bold; font-size:10pt;'>"+upper(T_YOU)+"</div>" +
                   "<div style='line-height:1.5;'>" + substr(cCmd, nl, "<br>") + "</div></div>" +
                   "</td></tr></table>"
                   
        oHistory.append(cUserMsg)
        oInput.setPlainText("")
        
        oStatusIndicator.setText("Thinking...")
        oStatusIndicator.setStyleSheet("color: orange; font-weight: bold;")
        oApp.processEvents()
        
        oRes = oCoreAgent.processMessage(cCmd, "")
        
        oStatusIndicator.setText(T_ONLINE)
        oStatusIndicator.setStyleSheet("color: #3fb950; font-weight: bold;")
        
        # ---------------------------------------------------------
        # Since SmartAgent already calls oUIManager.displayAIMessage() 
        # and oUIManager.showThinkingContent() within the agentic loop,
        # we don't need to display the final result separately anymore.
        //?  oCoreAgent.getTotalTokens()
        oTokenLabel.setText(T_TOKENS + oCoreAgent.getTotalTokens())
        
        # Update model/provider label if it changed
        cMdl = oCoreAgent.oSmartAgent.oAIClient.cGeminiModel
        switch oCoreAgent.oSmartAgent.oAIClient.cCurrentProvider
            on "openai" cMdl = oCoreAgent.oSmartAgent.oAIClient.cOpenAIModel
            on "claude" cMdl = oCoreAgent.oSmartAgent.oAIClient.cClaudeModel
            on "openrouter" cMdl = oCoreAgent.oSmartAgent.oAIClient.cOpenRouterModel
        off
        oModelLabel.setText("Model: " + cMdl)
        oProviderLabel.setText("Provider: " + oCoreAgent.oSmartAgent.oAIClient.cCurrentProvider)
        
        oHistory.verticalScrollBar().setValue(oHistory.verticalScrollBar().maximum())

        if substr(lower(cCmd), "save") or substr(lower(cCmd), "create")
            refreshSessionsList()
        ok

    func saveSessionJSON
        oCoreAgent.oSmartAgent.saveHistory()
        oHistory.append("<div style='color:#3fb950; text-align:center;'>Session saved (JSON)</div>")
        refreshSessionsList()

    func saveSessionText
        cFile = "chats/session_" + oCoreAgent.oSmartAgent.cSessionId + ".txt"
        oCoreAgent.oSmartAgent.saveToText(cFile)
        oHistory.append("<div style='color:#3fb950; text-align:center;'>Session saved (Text)</div>")

    func saveSessionMD
        cFile = "chats/session_" + oCoreAgent.oSmartAgent.cSessionId + ".md"
        oCoreAgent.oSmartAgent.saveToMD(cFile)
        oHistory.append("<div style='color:#3fb950; text-align:center;'>Session saved (MD)</div>")

    func clearSession
        oCoreAgent.newSession()
        oTokenLabel.setText(T_TOKENS + "0")
        oHistory.setHtml("<div style='color:#8b949e; text-align:center; margin-top:50px;'>New empty session started</div>")

    func loadSelectedSession
        nRow = oListSessions.currentRow()
        if nRow >= 0 and nRow < len(aSessionsFiles)
            cFile = aSessionsFiles[nRow + 1]
            oHistory.setHtml("<div style='color:#58a6ff; text-align:center;'><b>Loading...</b></div>")
            if oCoreAgent.loadSession(cFile)
                oHistory.setHtml("")
                aHist = oCoreAgent.oSmartAgent.oContextEngine.aConversationHistory
                for oMsg in aHist
                    if type(oMsg) != "LIST" loop ok
                    cRole = getValueFromList(oMsg, "role", "")
                    cContent = getValueFromList(oMsg, "content", "")
                    for pair in oMsg
                        if pair[1] = "parts" and type(pair[2]) = "LIST"
                            for oPart in pair[2]
                                if type(oPart) = "LIST"
                                    for oPP in oPart
                                        if oPP[1] = "text" cContent += oPP[2] ok
                                    next
                                ok
                            next
                        ok
                    next
                    if lower(cRole) = "user"
                        oHistory.append("<div style='height:15px;'></div><table width='100%'><tr><td align='right'><div style='background-color:#0969da; color:white; border-radius:18px 18px 2px 18px; padding:15px 22px; font-size:12pt; display:inline-block; max-width:80%;'><div style='margin-bottom:8px; opacity:0.8; font-weight:bold; font-size:10pt;'>"+upper(T_YOU)+"</div><div style='line-height:1.5;'>" + substr(cContent, nl, "<br>") + "</div></div></td></tr></table>")
                    else
                        oHistory.append("<div style='height:15px;'></div><table width='100%'><tr><td align='left'><div style='background-color:#161b22; color:#e1e4e8; border: 1px solid #30363d; border-radius:18px 18px 18px 2px; padding:15px 22px; font-size:12pt; max-width:85%;'><div style='margin-bottom:8px;'><span style='color:"+C_PRIMARY_COLOR+"; font-weight:bold; font-size:11pt;'>✦ " + upper(T_AGENT) + "</span></div><div style='line-height:1.6;'>" + renderMarkdown(cContent) + "</div></div></td></tr></table><div style='height:5px;'></div>")
                    ok
                next
                oTokenLabel.setText(T_TOKENS + oCoreAgent.getTotalTokens())
                cMdl = oCoreAgent.oSmartAgent.oAIClient.cGeminiModel
                switch oCoreAgent.oSmartAgent.oAIClient.cCurrentProvider
                    on "openai" cMdl = oCoreAgent.oSmartAgent.oAIClient.cOpenAIModel
                    on "claude" cMdl = oCoreAgent.oSmartAgent.oAIClient.cClaudeModel
                    on "openrouter" cMdl = oCoreAgent.oSmartAgent.oAIClient.cOpenRouterModel
                off
                oModelLabel.setText("Model: " + cMdl)
                oProviderLabel.setText("Provider: " + oCoreAgent.oSmartAgent.oAIClient.cCurrentProvider)
                oHistory.verticalScrollBar().setValue(oHistory.verticalScrollBar().maximum())
            ok
        ok

    func deleteSelectedSession
        nRow = oListSessions.currentRow()
        if nRow >= 0 and nRow < len(aSessionsFiles)
            cFile = aSessionsFiles[nRow + 1]
            if oCoreAgent.deleteSession(cFile)
                refreshSessionsList()
                oHistory.append("<div style='color:#f85149; text-align:center;'>Session deleted</div>")
            ok
        ok

    func toggleAuth
        if oAuthCheck.isChecked()
            oCoreAgent.authorizeSession()
            oHistory.append("<div style='color:#3fb950; text-align:center;'>Session authorized</div>")
        else
            oCoreAgent.revokeAuthorization()
            oHistory.append("<div style='color:#f85149; text-align:center;'>Session revoked</div>")
        ok

    func toggleLanguage
        if C_LANG = "EN"
            C_LANG = "AR"
            T_TITLE    = "فلاش للذكاء الاصطناعي"
            T_SESSIONS = "المحادثات السابقة"
            T_AUTH     = "الصلاحيات الكاملة"
            T_NEW      = "محادثة جديدة"
            T_DELETE   = "حذف"
            T_SAVE_JSON = "حفظ JSON"
            T_SAVE_TEXT = "حفظ Text"
            T_SAVE_MD   = "حفظ MD"
            T_SAVE      = "حفظ المحادثة"
            T_PLACE    = "اكتب طلبك هنا... (Enter للإرسال، Shift+Enter لسطر جديد)"
            T_EXEC     = "إرسال"
            T_ONLINE   = "متصل"
            T_YOU      = "أنت"
            T_AGENT    = "ذكاء فلاش"
            T_TOKENS   = "الكلمات: "
            oWin.setLayoutDirection(Qt_RightToLeft)
            oBtnLang.setText("إنجليزي")
            oCoreAgent.setLanguage("AR")
            T_SEC_TITLE = "تنبيه أمان"
            T_SEC_MSG   = "يطلب الذكاء الاصطناعي تنفيذ إجراء حساس. هل تسمح بذلك؟"
        else
            C_LANG = "EN"
            T_TITLE    = "FLASH AI — Super Engineer"
            T_SESSIONS = "Session History"
            T_AUTH     = "Full Permissions"
            T_NEW      = "New Session"
            T_DELETE   = "Delete Session"
            T_SAVE_JSON = "JSON"
            T_SAVE_TEXT = "Text"
            T_SAVE_MD   = "MD"
            T_SAVE      = "Save Chat"
            T_PLACE    = "Type your request... (Enter to Send, Shift+Enter for newline)"
            T_EXEC     = "Execute"
            T_ONLINE   = "● Online"
            T_YOU      = "You"
            T_AGENT    = "FLASH AI"
            T_TOKENS   = "Tokens: "
            oWin.setLayoutDirection(Qt_LeftToRight)
            oBtnLang.setText("العربية")
            oCoreAgent.setLanguage("EN")
            T_SEC_TITLE = "Security Alert"
            T_SEC_MSG   = "The AI is requesting to perform a sensitive action. Do you authorize this?"
        ok
        
        oWin.setwindowtitle(T_TITLE)
        oSideTitle.setText(T_SESSIONS)
        oAuthCheck.setText(T_AUTH)
        oBtnClear.setText(T_NEW)
        oBtnDelete.setText(T_DELETE)
        oBtnSaveJSON.setText(T_SAVE_JSON)
        oBtnSaveText.setText(T_SAVE_TEXT)
        oBtnSaveMD.setText(T_SAVE_MD)
        oTitleLabel.setText(T_TITLE)
        oStatusIndicator.setText(T_ONLINE)
        oTokenLabel.setText(T_TOKENS + oCoreAgent.getTotalTokens())
        oInput.setPlaceholderText(T_PLACE)
        oSend.setText(T_EXEC)

class GUIManager
    func displayAIMessage cMsg
        if isGlobal("oFlashGUI") oFlashGUI.displayAIMessageInternal(cMsg) ok

    func showThinkingContent cThought
        if isGlobal("oFlashGUI")
            cThoughtHtml = "<div style='height:10px;'></div>" +
                           "<div style='background-color:#0d1117; border: 1px dashed #30363d; border-radius:12px; padding:15px; margin:10px 50px; color:#c9d1d9; font-style:italic; font-size:10.5pt; shadow: inset 0 0 10px rgba(0,0,0,0.5);'>" +
                           "<div style='color:#58a6ff; font-weight:bold; font-style:normal; margin-bottom:5px; font-size:9pt;'>🔍 SYSTEM_REASONING</div>" + 
                           renderMarkdown(cThought) + "</div>"
            oFlashGUI.oHistory.append(cThoughtHtml)
        ok
    func displayToolAction cToolName, cDetails
        if isGlobal("oFlashGUI")
            oFlashGUI.displayToolActionInternal(cToolName, cDetails)
        ok

    func displaySystemNote(cNote)
        if isGlobal("oFlashGUI")
            cHtml = "<div style='color:#cca700; font-family:monospace; margin:5px 20px; font-weight:bold;'>[SYSTEM NOTE] " + cNote + "</div>"
            oFlashGUI.oHistory.append(cHtml)
            oFlashGUI.oHistory.verticalScrollBar().setValue(oFlashGUI.oHistory.verticalScrollBar().maximum())
            oFlashGUI.oApp.processEvents()
        ok

    func setToolsCount n
    func setLanguage cLang
    func processEvents
    func askConfirmation cToolName, cDetails
        return true
