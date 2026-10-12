# ===================================================================
# FLASH AI - Test Suite: Skills (Markdown) & Memory Management
# Tests Markdown-based Progressive Disclosure Skills and Memory
# ===================================================================

load "stdlib.ring"
load "src/loadFiles.ring"

nPass = 0
nFail = 0
nTotal = 0

func main {
    see "=================================================" + nl
    see "  FLASH AI Test Suite - Skills & Memory Module" + nl
    see "=================================================" + nl + nl

    # -----------------------------------------------------------------
    # Part 1: SkillsManager (Markdown Skills in skills/)
    # -----------------------------------------------------------------
    see "--- Testing SkillsManager (Markdown Skills) ---" + nl

    oMgr = new SkillsManager()
    aSkills = oMgr.getSkills()
    testCondition("SkillsManager: scanned built-in skills", len(aSkills) >= 3)

    # Catalog Prompt
    cCatalog = oMgr.getSkillsCatalogPrompt()
    testCondition("SkillsManager: catalog prompt contains ring_code_master", substr(cCatalog, "ring_code_master") > 0)
    testCondition("SkillsManager: catalog prompt contains ring_gui_development", substr(cCatalog, "ring_gui_development") > 0)

    # Read specific skill
    aSkillRes = oMgr.getSkill("ring_code_master")
    testCondition("SkillsManager: getSkill returns true", aSkillRes[1] = true)
    testCondition("SkillsManager: getSkill has content", substr(aSkillRes[2], "Ring Code Master") > 0)

    # Save a new custom Markdown skill
    cCustomMD = "# Web Scraping Skill" + nl + nl +
                "## Guidelines" + nl +
                "Use libcurl to download web pages." + nl
    aSaveRes = oMgr.saveSkill("web_scraper_test", "Scrapes web content with libcurl", cCustomMD)
    testCondition("SkillsManager: saveSkill succeeds", aSaveRes[1] = true)
    testCondition("SkillsManager: file created on disk", fexists(APP_PATH("skills/web_scraper_test/SKILL.md")))

    # Delete custom skill
    aDelRes = oMgr.deleteSkill("web_scraper_test")
    testCondition("SkillsManager: deleteSkill succeeds", aDelRes[1] = true)
    testCondition("SkillsManager: file removed from disk", not fexists(APP_PATH("skills/web_scraper_test/SKILL.md")))

    # -----------------------------------------------------------------
    # Part 2: AgentTools Skills Interface
    # -----------------------------------------------------------------
    see nl + "--- Testing AgentTools Skills Interface ---" + nl

    oTools = new AgentTools()

    # 1. list_skills
    oRes = oTools.executeTool("list_skills", [])
    testCondition("Tool list_skills: success", oRes[:success] = true)
    testCondition("Tool list_skills: mentions ring_code_master", substr(oRes[:message], "ring_code_master") > 0)

    # 2. activate_skill
    oRes = oTools.executeTool("activate_skill", [["skill_name", "ring_gui_development"]])
    testCondition("Tool activate_skill: loads instructions", oRes[:success] = true and substr(oRes[:message], "RingQt") > 0)

    # 3. save_skill
    oRes = oTools.executeTool("save_skill", [
        ["skill_name", "agent_testing_guide"],
        ["description", "Best practices for writing unit tests"],
        ["markdown_content", "# Testing Guidelines\n1. Use testCondition\n2. Track nPass and nFail"]
    ])
    testCondition("Tool save_skill: creates markdown skill", oRes[:success] = true)

    # 4. read newly saved skill
    oRes = oTools.executeTool("activate_skill", [["skill_name", "agent_testing_guide"]])
    testCondition("Tool activate_skill: reads saved skill", oRes[:success] = true and substr(oRes[:message], "testCondition") > 0)

    # 5. delete_skill
    oRes = oTools.executeTool("delete_skill", [["skill_name", "agent_testing_guide"]])
    testCondition("Tool delete_skill: removes skill", oRes[:success] = true)

    # -----------------------------------------------------------------
    # Part 3: LongTermMemory Tests
    # -----------------------------------------------------------------
    see nl + "--- Testing LongTermMemory & Markdown Sync ---" + nl

    oMem = new LongTermMemory
    
    # Store facts
    oMem.remember("user_preference", "User prefers Arabic and English explanations", 9)
    oMem.remember("project_fact", "Flash AI is built in Ring language", 8)
    oMem.remember("code_pattern", "Use safeSystem for subprocess execution", 7)

    testCondition("Memory remember: has items", len(oMem.getAllMemories()) >= 3)

    # Recall
    aRecalled = oMem.recall("Arabic", 5)
    testCondition("Memory recall: finds Arabic preference", len(aRecalled) > 0)

    # Export Markdown
    cMD = oMem.exportMarkdown()
    testCondition("Memory exportMarkdown: contains header", substr(cMD, "FLASH AI - Long-Term Knowledge Base") > 0)

    # Sync to disk
    oMem.syncMarkdownFile()
    cMDDisk = APP_PATH("ai/memory/MEMORY.md")
    testCondition("Memory sync: MEMORY.md exists", fexists(cMDDisk))

    # Render to HTML (via ysdragon/markdown)
    cHTML = oMem.renderToHTML("# Test Heading" + nl + "Hello Markdown!")
    testCondition("Markdown to HTML: returns non-empty HTML", len(cHTML) > 0 and substr(cHTML, "Heading") > 0)

    # Forget
    nForget = oMem.forget("safeSystem")
    testCondition("Memory forget: removes matching item", nForget > 0)

    # -----------------------------------------------------------------
    # Results Summary
    # -----------------------------------------------------------------
    see nl + "=================================================" + nl
    see "  Tests completed: " + nTotal + nl
    see "  Passed: " + nPass + nl
    see "  Failed: " + nFail + nl
    see "=================================================" + nl
}

func testCondition(cName, bCondition) {
    nTotal++
    if bCondition
        nPass++
        see "  [PASS] " + cName + nl
    else
        nFail++
        see "  [FAIL] " + cName + nl
    ok
}
