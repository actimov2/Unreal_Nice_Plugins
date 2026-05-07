# Unreal_Nice_Plugins

Monorepo สำหรับเก็บ Unreal Engine 5.6+ plugins โดยใช้ git submodules — แต่ละ plugin มี repo ของตัวเอง แต่ทดสอบ/พัฒนาร่วมกันได้ใน Host project เดียว

## โครงสร้าง

```
Unreal_Nice_Plugins/                 ← repo นี้ (public)
├── HostProject/                     ← UE5 project สำหรับ test plugin
│   ├── HostProject.uproject
│   ├── Source/
│   ├── Config/
│   └── Plugins/                     ← submodules มาวางที่นี่
│       ├── SamplePlugin/            ← submodule → repo ของ SamplePlugin (private)
│       └── <plugin อื่นๆ>/
├── scripts/                         ← PowerShell automation
│   ├── new-plugin.ps1               ← สร้าง plugin ใหม่ + push ขึ้น GitHub
│   ├── add-plugin.ps1               ← add plugin ที่มี repo อยู่แล้วเป็น submodule
│   └── regenerate.ps1               ← regenerate VS project files
├── docs/
│   └── WORKFLOW.md                  ← วิธีใช้งานแบบละเอียด
├── .vscode/                         ← VS Code tasks/settings/launch
├── .clang-format                    ← Epic UE5 coding standard
├── .editorconfig                    ← cross-editor formatting
└── .gitignore
```

## Quick start

ครั้งแรกที่ clone (รวม submodules):

```powershell
git clone --recursive https://github.com/actimov2/Unreal_Nice_Plugins.git
cd Unreal_Nice_Plugins
```

ถ้าลืมใส่ `--recursive`:

```powershell
git submodule update --init --recursive
```

เปิด HostProject:

```powershell
# Right-click HostProject\HostProject.uproject → Generate Visual Studio project files
# หรือใช้ task:
# VS Code → Ctrl+Shift+P → "Tasks: Run Task" → "UE: Regenerate project files"
```

แล้ว double-click `HostProject.uproject` → UE Editor จะเปิดพร้อม plugins ทั้งหมด

## สร้าง plugin ใหม่

```powershell
.\scripts\new-plugin.ps1 -Name MyAwesomePlugin
```

Script จะ:
1. สร้าง folder + .uplugin + Source/ skeleton ใน `HostProject/Plugins/MyAwesomePlugin/`
2. `git init` ใน folder นั้น
3. สร้าง private repo บน GitHub ผ่าน `gh` CLI
4. Push code ขึ้น GitHub
5. Add กลับเข้ามาเป็น submodule ของ repo หลัก
6. Commit `.gitmodules`

## เพิ่ม plugin ที่มี repo อยู่แล้ว

```powershell
.\scripts\add-plugin.ps1 -Url https://github.com/actimov2/SomePlugin.git -Name SomePlugin
```

## Switch ระหว่าง plugin ต่างๆ

ดู `docs/WORKFLOW.md` สำหรับรายละเอียด — สั้นๆ คือ:

- **เปิดทุก plugin พร้อมกัน:** เปิด VS Code ที่ root `Unreal_Nice_Plugins/`
- **โฟกัส plugin เดียว:** เปิด VS Code ที่ `HostProject/Plugins/<PluginName>/`
- **ทดสอบใน UE:** เปิด `HostProject.uproject` — ทุก plugin ที่ enabled จะโหลดอัตโนมัติ

## Requirements

- Windows 10/11
- Unreal Engine 5.6+
- Visual Studio 2022 (with **Game development with C++** workload)
- Git for Windows
- VS Code
- GitHub CLI (`gh`) — สำหรับ `new-plugin.ps1` ใช้สร้าง repo อัตโนมัติ
  ```powershell
  winget install GitHub.cli
  gh auth login
  ```

## License

Host project: MIT (ดู LICENSE)
แต่ละ plugin มี license ของตัวเองใน repo ของ plugin นั้น
