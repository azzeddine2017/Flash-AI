class ThemeManager
    cCurrentTheme = "deepagents"
    
    # Default 'deepagents' colors
    cPrimaryColor = CYAN
    cSecColor = DARKGREY
    cAccentColor = LIGHTGREEN
    cErrorColor = LIGHTRED
    cWarnColor = YELLOW
    cTextColor = WHITE
    cBorderColor = CYAN
    
    func setTheme cName
        cCurrentTheme = lower(trim(cName))
        switch cCurrentTheme
            on "hacker"
                cPrimaryColor = LIGHTGREEN
                cSecColor = GREEN
                cAccentColor = WHITE
                cErrorColor = LIGHTRED
                cWarnColor = YELLOW
                cTextColor = LIGHTGREEN
                cBorderColor = GREEN
            on "light"
                cPrimaryColor = BLUE
                cSecColor = GREY
                cAccentColor = MAGENTA
                cErrorColor = RED
                cWarnColor = BROWN
                cTextColor = BLACK
                cBorderColor = LIGHTBLUE
            other # deepagents
                cPrimaryColor = CYAN
                cSecColor = DARKGREY
                cAccentColor = LIGHTGREEN
                cErrorColor = LIGHTRED
                cWarnColor = YELLOW
                cTextColor = WHITE
                cBorderColor = CYAN
        off
        
    func getPrimary  return cPrimaryColor
    func getSec      return cSecColor
    func getAccent   return cAccentColor
    func getError    return cErrorColor
    func getWarn     return cWarnColor
    func getText     return cTextColor
    func getBorder   return cBorderColor
