# ===================================================================
# ThemeManager - Centralized Theme Management System
# ===================================================================
# Provides:
#   - Theme switching between 'deepagents', 'hacker', and 'light'
#   - Centralized color management for all UI components
#   - Easy extension for new themes
# ===================================================================


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

    # ===================================================================
    # Set Theme
    # ===================================================================
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
    # ===================================================================
    # Get Primary Color
    # ===================================================================    
    func getPrimary  return cPrimaryColor
    # ===================================================================
    # Get Secondary Color
    # ===================================================================
    func getSec      return cSecColor
    # ===================================================================
    # Get Accent Color
    # ===================================================================
    func getAccent   return cAccentColor
    # ===================================================================
    # Get Error Color
    # ===================================================================
    # Get Error Color
    # ===================================================================
    func getError    return cErrorColor
    # ===================================================================
    # Get Warning Color
    # ===================================================================
    func getWarn     return cWarnColor
    # ===================================================================
    # Get Text Color
    # ===================================================================
    func getText     return cTextColor
    # ===================================================================
    # Get Border Color
    # ===================================================================
    func getBorder   return cBorderColor
