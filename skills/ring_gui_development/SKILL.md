---
name: ring_gui_development
description: Authoritative guide for building desktop graphical user interfaces with RingQt in Ring. Use this skill when asked to create or modify GUI applications.
---

# Ring GUI Development Skill (RingQt)

## Purpose
Teaches Flash AI the exact paradigms, layout techniques, and widget bindings for constructing modern GUI applications using `guilib.ring` (RingQt).

## Standard Architecture

### 1. Boilerplate Template
```ring
load "guilib.ring"

func main {
    new qApp {
        new qWidget() {
            setWindowTitle("Flash Application")
            resize(800, 600)
            
            # Use layouts for responsive scaling
            oLayout = new qVBoxLayout() {
                oLabel = new qLabel(this) {
                    setText("Welcome to Flash AI GUI")
                    setAlignment(Qt_AlignCenter)
                }
                addWidget(oLabel)
                
                oBtn = new qPushButton(this) {
                    setText("Click Me")
                    setClickEvent("btnAction()")
                }
                addWidget(oBtn)
            }
            setLayout(oLayout)
            show()
        }
        exec()
    }
}

func btnAction {
    see "Button clicked!" + nl
}
```

### 2. Core UI Principles
- **Layouts First**: Avoid hardcoding absolute positions with `move()` or `resize()` for widgets; always nest widgets inside `qVBoxLayout` or `qHBoxLayout`.
- **Event Handling**: Set event callbacks with strings: `setClickEvent("myFunc()")`.
- **Modularity**: Separate GUI layout from business logic by placing application logic in dedicated helper classes or controller functions.
