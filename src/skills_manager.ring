# ===================================================================
# FLASH AI - Skills Manager (Markdown-Based Progressive Disclosure)
# ===================================================================
# Manages specialized skills stored as Markdown files in skills/
# Skills provide deep, on-demand domain instructions and workflows
# without overloading the agent's base prompt context window.
# ===================================================================

class SkillsManager

    cSkillsDir = ""
    aSkills = []

    # ===================================================================
    # Constructor
    # ===================================================================
    func init()
        cSkillsDir = APP_PATH("skills")
        if iswindows()
            cSkillsDir = substr(cSkillsDir, "/", "\")
        ok
        ensureDirectoryExists(cSkillsDir)
        scanSkills()

    # ===================================================================
    # Scan and Index Available Skills
    # ===================================================================
    func scanSkills()
        aSkills = []
        if not dirExists(cSkillsDir)
            return aSkills
        ok

        aEntries = dir(cSkillsDir)
        for item in aEntries
            cName = item[1]
            bIsDir = (item[2] = 1)

            # Skip hidden or system folders
            if cName = "." or cName = ".." or left(cName, 1) = "."
                loop
            ok

            cSkillPath = ""
            cSkillKey = ""

            if bIsDir
                # Directory style: skills/<skill_name>/SKILL.md or <skill_name>.md
                cTryFile1 = cSkillsDir + "/" + cName + "/SKILL.md"
                cTryFile2 = cSkillsDir + "/" + cName + "/" + cName + ".md"
                if iswindows()
                    cTryFile1 = substr(cTryFile1, "/", "\")
                    cTryFile2 = substr(cTryFile2, "/", "\")
                ok
                if fexists(cTryFile1)
                    cSkillPath = cTryFile1
                    cSkillKey = cName
                elseif fexists(cTryFile2)
                    cSkillPath = cTryFile2
                    cSkillKey = cName
                ok
            else
                # Standalone file style: skills/<skill_name>.md
                if right(lower(cName), 3) = ".md"
                    cSkillPath = cSkillsDir + "/" + cName
                    if iswindows() cSkillPath = substr(cSkillPath, "/", "\") ok
                    cSkillKey = substr(cName, 1, len(cName) - 3)
                ok
            ok

            if cSkillPath != ""
                cContent = read(cSkillPath)
                aMeta = extractFrontmatter(cContent, cSkillKey)

                oSkill = [
                    ["name", aMeta[1]],
                    ["description", aMeta[2]],
                    ["title", aMeta[3]],
                    ["path", cSkillPath],
                    ["is_dir", bIsDir]
                ]
                Add(aSkills, oSkill)
            ok
        next

        return aSkills

    # ===================================================================
    # Extract Metadata (YAML Frontmatter or Top Markdown Header)
    # ===================================================================
    func extractFrontmatter(cText, cFallbackName)
        cName = cFallbackName
        cDesc = "Specialized skill for Flash AI"
        cTitle = cFallbackName

        # 1. High-Performance PCRE2 RegEx extraction
        if isclass("RegEx")
            try
                oReg = new RegEx("(?is)^---\s*\r?\n(.*?)\r?\n---", 0)
                aMatches = oReg.findAll(cText)
                if len(aMatches) > 0 and len(aMatches[1]) >= 2
                    cHeader = aMatches[1][2]
                    
                    oNameReg = new RegEx("(?im)^name:\s*(.*?)$", 0)
                    aN = oNameReg.findAll(cHeader)
                    if len(aN) > 0 and len(aN[1]) >= 2 cName = trim(aN[1][2]) ok
                    
                    oDescReg = new RegEx("(?im)^(?:description|desc):\s*(.*?)$", 0)
                    aD = oDescReg.findAll(cHeader)
                    if len(aD) > 0 and len(aD[1]) >= 2 cDesc = trim(aD[1][2]) ok

                    oTitleReg = new RegEx("(?im)^title:\s*(.*?)$", 0)
                    aT = oTitleReg.findAll(cHeader)
                    if len(aT) > 0 and len(aT[1]) >= 2 cTitle = trim(aT[1][2]) ok

                    return [cName, cDesc, cTitle]
                ok
            catch
            done
        ok

        # 2. Resilient Substring / Line fallback
        cTrim = trim(cText)
        if left(cTrim, 3) = "---"
            cAfter = substr(cTrim, 4)
            nEnd = substr(cAfter, "---")
            if nEnd > 0
                cHeader = substr(cAfter, 1, nEnd - 1)
                aLines = split(cHeader, nl)
                for cLine in aLines
                    cLine = trim(cLine)
                    if left(lower(cLine), 5) = "name:"
                        cName = trim(substr(cLine, 6))
                    elseif left(lower(cLine), 12) = "description:"
                        cDesc = trim(substr(cLine, 13))
                    elseif left(lower(cLine), 5) = "desc:"
                        cDesc = trim(substr(cLine, 6))
                    elseif left(lower(cLine), 6) = "title:"
                        cTitle = trim(substr(cLine, 7))
                    ok
                next
                return [cName, cDesc, cTitle]
            ok
        ok

        # Fallback: extract first # Header as title and first blockquote or sentence as desc
        aLines = split(cTrim, nl)
        for i = 1 to len(aLines)
            cLine = trim(aLines[i])
            if left(cLine, 2) = "# "
                cTitle = trim(substr(cLine, 3))
            elseif left(cLine, 2) = "> " and cDesc = "Specialized skill for Flash AI"
                cDesc = trim(substr(cLine, 3))
            elseif cLine != "" and left(cLine, 1) != "#" and cDesc = "Specialized skill for Flash AI"
                cDesc = cLine
                if len(cDesc) > 150
                    cDesc = left(cDesc, 147) + "..."
                ok
            ok
        next

        return [cName, cDesc, cTitle]

    # ===================================================================
    # Get All Indexed Skills
    # ===================================================================
    func getSkills()
        return aSkills

    # ===================================================================
    # Build Compact Skills Catalog for System Prompt / Context
    # ===================================================================
    func getSkillsCatalogPrompt()
        if len(aSkills) = 0
            return ""
        ok

        cPrompt = "[SKILLS LIBRARY - Specialized On-Demand Knowledge]" + nl
        cPrompt += "Flash AI can activate any of the following skills by calling activate_skill(skill_name):" + nl
        for oSkill in aSkills
            cName = getValueFromList(oSkill, "name", "")
            cDesc = getValueFromList(oSkill, "description", "")
            cPrompt += "• " + cName + ": " + cDesc + nl
        next
        cPrompt += "Call activate_skill when tackling a task covered by one of these skills." + nl
        cPrompt += "[END SKILLS LIBRARY]" + nl
        return cPrompt

    # ===================================================================
    # Get Specific Skill Content
    # ===================================================================
    func getSkill(cSkillName)
        cKey = lower(trim(cSkillName))
        for oSkill in aSkills
            if lower(getValueFromList(oSkill, "name", "")) = cKey
                cPath = getValueFromList(oSkill, "path", "")
                if fexists(cPath)
                    return [true, read(cPath), cPath, getValueFromList(oSkill, "description", "")]
                ok
            ok
        next
        return [false, "Skill '" + cSkillName + "' not found.", "", ""]

    # ===================================================================
    # Create or Update a Skill (Markdown Format)
    # ===================================================================
    func saveSkill(cSkillName, cDescription, cMarkdownContent)
        try
            cSkillName = trim(cSkillName)
            if cSkillName = ""
                return [false, "Skill name cannot be empty."]
            ok

            # Sanitize name
            cSkillName = sanitizeShellArg(cSkillName)
            cSkillName = substr(cSkillName, "/", "")
            cSkillName = substr(cSkillName, "\", "")
            cSkillName = substr(cSkillName, "..", "")
            cSkillName = substr(cSkillName, " ", "_")

            cSkillDir = cSkillsDir + "/" + cSkillName
            if iswindows()
                cSkillDir = substr(cSkillDir, "/", "\")
            ok
            ensureDirectoryExists(cSkillDir)
            cFilePath = cSkillDir + "/SKILL.md"
            if iswindows()
                cFilePath = substr(cFilePath, "/", "\")
            ok

            # Ensure Frontmatter exists
            cFinalMD = ""
            cTrimMD = trim(cMarkdownContent)
            if left(cTrimMD, 3) != "---"
                cFinalMD = "---" + nl +
                           "name: " + cSkillName + nl +
                           "description: " + trim(cDescription) + nl +
                           "---" + nl + nl +
                           cMarkdownContent
            else
                cFinalMD = cMarkdownContent
            ok

            write(cFilePath, cFinalMD)
            scanSkills()
            return [true, "Skill '" + cSkillName + "' successfully saved at " + cFilePath]
        catch
            return [false, "Error saving skill: " + cCatchError]
        done

    # ===================================================================
    # Delete a Skill
    # ===================================================================
    func deleteSkill(cSkillName)
        try
            cKey = lower(trim(cSkillName))
            for i = 1 to len(aSkills)
                if lower(getValueFromList(aSkills[i], "name", "")) = cKey
                    cPath = getValueFromList(aSkills[i], "path", "")
                    bIsDir = getValueFromList(aSkills[i], "is_dir", false)

                    if fexists(cPath)
                        remove(cPath)
                    ok

                    # If it was in its own directory, try to remove the directory
                    if bIsDir
                        cDir = cSkillsDir + "/" + getValueFromList(aSkills[i], "name", "")
                        # Try to remove any remaining files
                        try
                            aFiles = dir(cDir)
                            for f in aFiles
                                if f[2] = 0 remove(cDir + "/" + f[1]) ok
                            next
                        catch done
                    ok

                    scanSkills()
                    return [true, "Skill '" + cSkillName + "' deleted successfully."]
                ok
            next
            return [false, "Skill '" + cSkillName + "' not found."]
        catch
            return [false, "Error deleting skill: " + cCatchError]
        done
