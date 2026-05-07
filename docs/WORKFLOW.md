# Workflow Guide

วิธีทำงานกับ Unreal_Nice_Plugins ในแต่ละสถานการณ์

## ตั้งค่าครั้งแรก (one-time setup)

### 1. ติดตั้งเครื่องมือที่ต้องมี

```powershell
# จาก PowerShell admin
winget install Microsoft.VisualStudio.2022.Community  # ติ๊ก "Game development with C++"
winget install Microsoft.VisualStudioCode
winget install Git.Git
winget install GitHub.cli

# UE 5.6 ติดตั้งผ่าน Epic Games Launcher
```

### 2. ตั้งตัวแปร environment `UE_ROOT`

VS Code tasks และ scripts ต้องการ env var ชี้ไปที่ UE install:

```powershell
# ใน PowerShell admin
[Environment]::SetEnvironmentVariable('UE_ROOT', 'C:\Program Files\Epic Games\UE_5.6', 'User')
```

ปิด-เปิด VS Code/PowerShell ใหม่หลังตั้งค่า

### 3. Login GitHub CLI

```powershell
gh auth login
# เลือก GitHub.com → HTTPS → login with browser
```

### 4. Clone repo

```powershell
cd E:\[Claude_Project]
git clone --recursive https://github.com/actimov2/Unreal_Nice_Plugins.git
```

ถ้า clone ไปแล้วลืม `--recursive`:
```powershell
cd Unreal_Nice_Plugins
git submodule update --init --recursive
```

### 5. Build ครั้งแรก

```powershell
# regenerate VS project files
.\scripts\regenerate.ps1
```

แล้วเปิด `HostProject.uproject` — UE จะถามว่า "missing modules, build now?" → กด Yes

---

## Use case ต่างๆ

### A. เริ่ม plugin ใหม่จากศูนย์

```powershell
.\scripts\new-plugin.ps1 -Name CoolPathfinder -Description "A* pathfinding utilities"
```

Script ทำให้ครบ:
- copy SamplePlugin → rename → init git → push GitHub → add submodule → commit

หลังจากนั้น:
1. รัน task **UE: Regenerate project files** (Ctrl+Shift+P → Tasks: Run Task)
2. เปิด HostProject ใน UE Editor

### B. ดึง plugin ที่เพื่อนทำไว้แล้วมาใช้

```powershell
.\scripts\add-plugin.ps1 -Url https://github.com/someone/CoolPlugin.git
```

แก้ `HostProject/HostProject.uproject` เพิ่ม:
```json
"Plugins": [
    { "Name": "CoolPlugin", "Enabled": true }
]
```

Regenerate → build → เปิด editor

### C. Switch ทำงานข้าม plugin (สำคัญ!)

มี **3 mode** ให้เลือกตามสถานการณ์:

#### Mode 1: ทำงานหลาย plugin พร้อมกัน
```powershell
code E:\[Claude_Project]\Unreal_Nice_Plugins
```
- เห็นทุก plugin ใน Explorer
- เหมาะตอน plugin คุยกันเอง หรือเปลี่ยนหลายตัวพร้อมกัน

#### Mode 2: โฟกัส plugin เดียว (แนะนำสำหรับมือใหม่)
```powershell
code E:\[Claude_Project]\Unreal_Nice_Plugins\HostProject\Plugins\CoolPathfinder
```
- workspace สะอาด เห็นแค่ plugin นั้น
- Git operations (commit/push) จะอยู่ใน repo ของ plugin โดยตรง
- ยังใช้ `.clang-format` จาก root ได้ (clang-format หา parent dirs อัตโนมัติ)

#### Mode 3: Multi-root workspace (advanced)
สร้างไฟล์ `Unreal_Nice_Plugins.code-workspace`:
```json
{
  "folders": [
    { "name": "🏠 Host", "path": "." },
    { "name": "📦 CoolPathfinder", "path": "HostProject/Plugins/CoolPathfinder" },
    { "name": "📦 SamplePlugin", "path": "HostProject/Plugins/SamplePlugin" }
  ]
}
```
double-click ไฟล์นี้เปิดใน VS Code — ได้ทุก plugin เป็น root แยก, แต่ละ root มี git status ของตัวเอง

### D. Build / Run

VS Code มี tasks ให้แล้ว — กด `Ctrl+Shift+B` แล้วเลือก:
- **UE: Build HostProject (Editor, Dev)** — build ปกติ (default, Ctrl+Shift+B โดดๆ)
- **UE: Rebuild HostProject** — clean + build (ตอน build error งี่เง่าๆ)
- **UE: Open HostProject in Editor** — เปิด UE Editor

หรือใช้แบบเดิม: double-click `HostProject.sln` → เปิด Visual Studio → F5

### E. แก้ code ใน plugin แล้ว push

แต่ละ plugin มี repo ของตัวเอง ดังนั้น:

```powershell
cd HostProject\Plugins\CoolPathfinder
git add .
git commit -m "Add A* implementation"
git push origin main
```

จากนั้นที่ host repo จะเห็นว่า submodule pointer "ขยับ" — ต้อง commit ที่ host ด้วย:

```powershell
cd E:\[Claude_Project]\Unreal_Nice_Plugins
git add HostProject/Plugins/CoolPathfinder
git commit -m "Update CoolPathfinder submodule pointer"
git push
```

> **Tip:** submodule pointer = git commit ของ plugin ที่ host repo "ตรึง" ไว้
> ถ้าไม่ commit pointer ใหม่ คนอื่นที่ clone repo จะได้ plugin version เก่า

### F. Pull งานล่าสุด (รวม submodules)

```powershell
git pull
git submodule update --init --recursive
```

หรือ task **Git: Update all submodules** (จะดึง branch ล่าสุดของแต่ละ submodule ด้วย `--remote`)

### G. Ship plugin ตัวเดียวให้คนอื่น

เพราะแต่ละ plugin เป็น repo แยก — ส่ง URL ของ plugin repo ไปให้คนอื่นโดยตรง:

```
https://github.com/actimov2/CoolPathfinder
```

เขาเอาไปใส่ใน `Plugins/` ใน project ของเขาก็ใช้งานได้เลย ไม่ต้องเอา host repo ไปด้วย

---

## Troubleshooting ที่เจอบ่อย

### "Cannot find UnrealEditor.exe"
ตั้ง `UE_ROOT` env var ให้ถูก แล้วปิด-เปิด VS Code ใหม่

### Submodule folder ว่างเปล่า
```powershell
git submodule update --init --recursive
```

### Build error หลัง pull
```powershell
.\scripts\regenerate.ps1
```
แล้ว rebuild

### `gh repo create` fail ใน new-plugin.ps1
```powershell
gh auth status   # ถ้าไม่ login ให้ run: gh auth login
```

### IntelliSense ใน VS Code แดงเต็มไปหมด
VS Code IntelliSense ของ UE projects จะใช้ `compileCommands_HostProject.json` ที่ UE generate ตอน regenerate
- กด task **UE: Regenerate project files** อีกครั้ง
- ถ้ายังไม่หาย → ใช้ Visual Studio (full IDE) สำหรับ debugging IntelliSense ของ UE ลำบาก

### ทำไม UE Editor ไม่เห็น plugin ใหม่
ตรวจสอบ:
1. มี `.uplugin` ใน `Plugins/PluginName/` มั้ย
2. `HostProject.uproject` มี plugin ใน `"Plugins"` array มั้ย (`Enabled: true`)
3. Build ผ่านมั้ย — ถ้า plugin compile error UE จะ silently disable
