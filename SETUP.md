# Setup Guide — เริ่มใช้งานครั้งแรก

อ่านไฟล์นี้ก่อนครับ ทำตามทีละขั้นจะใช้เวลาประมาณ 15 นาที

## ขั้นที่ 0: ตรวจเครื่องมือ

เปิด PowerShell แล้วรัน:

```powershell
git --version       # ต้องมี
gh --version        # ต้องมี (GitHub CLI)
code --version      # VS Code ต้องมี
```

ถ้าไม่มี `gh`:
```powershell
winget install GitHub.cli
gh auth login
# เลือก: GitHub.com → HTTPS → Login with a web browser
```

## ขั้นที่ 1: Extract zip ไปที่ที่ต้องการ

แตก zip ลงที่ `E:\[Claude_Project]\Unreal_Nice_Plugins\`

โครงสร้างต้องเป็นแบบนี้:
```
E:\[Claude_Project]\Unreal_Nice_Plugins\
├── HostProject\
├── scripts\
├── README.md
├── .gitignore
└── ...
```

## ขั้นที่ 2: ตั้ง UE_ROOT environment variable

PowerShell admin:
```powershell
[Environment]::SetEnvironmentVariable('UE_ROOT', 'C:\Program Files\Epic Games\UE_5.6', 'User')
```

> ถ้า UE 5.6 อยู่ที่อื่น แก้ path ให้ตรง

ปิด-เปิด PowerShell ใหม่ แล้ว verify:
```powershell
echo $env:UE_ROOT
# ควรพิมพ์ path ออกมา
```

## ขั้นที่ 3: Init git + push host repo ขึ้น GitHub (Public)

```powershell
cd E:\[Claude_Project]\Unreal_Nice_Plugins

git init -b main
git add -A
git commit -m "Initial scaffold: host project, sample plugin, scripts, docs"

# สร้าง public repo ชื่อ Unreal_Nice_Plugins บน github.com/actimov2
gh repo create actimov2/Unreal_Nice_Plugins --public --source=. --push --description "Unreal Engine 5.6+ plugin monorepo with submodule-based plugins"
```

ถ้าทำสำเร็จจะมี link ขึ้นมา → เปิดดูได้ที่ https://github.com/actimov2/Unreal_Nice_Plugins

## ขั้นที่ 4: แยก SamplePlugin ออกเป็น repo ของตัวเอง

ตอนนี้ SamplePlugin อยู่ใน host repo แต่เราอยากให้มันเป็น **submodule** ที่ชี้ไปยัง repo ของตัวเอง

```powershell
cd E:\[Claude_Project]\Unreal_Nice_Plugins\HostProject\Plugins\SamplePlugin

# init เป็น repo แยก
git init -b main
git add -A
git commit -m "Initial commit: SamplePlugin template"

# push เป็น private repo
gh repo create actimov2/SamplePlugin --private --source=. --push --description "Minimal UE5 editor plugin template"

# กลับขึ้นมา host root
cd E:\[Claude_Project]\Unreal_Nice_Plugins

# ลบ folder เก่า แล้ว add กลับเป็น submodule
Remove-Item -Path "HostProject\Plugins\SamplePlugin" -Recurse -Force
git submodule add https://github.com/actimov2/SamplePlugin.git HostProject/Plugins/SamplePlugin
git add .gitmodules HostProject/Plugins/SamplePlugin
git commit -m "Convert SamplePlugin to submodule"
git push
```

## ขั้นที่ 5: Verify

```powershell
git submodule status
# ควรเห็น hash ตามด้วย HostProject/Plugins/SamplePlugin (heads/main)
```

เปิด VS Code:
```powershell
code .
```

VS Code จะแนะนำให้ติดตั้ง extensions (ที่ list ใน `.vscode/extensions.json`) — กด Install All

## ขั้นที่ 6: Build ครั้งแรก

```powershell
.\scripts\regenerate.ps1
```

แล้ว double-click `HostProject\HostProject.uproject` → UE จะถาม "missing modules, build now?" → Yes

ใช้เวลา compile ครั้งแรก 5-15 นาที (ขึ้นกับเครื่อง)

หลัง build เสร็จ UE Editor เปิดขึ้น → ดู toolbar ด้านบน จะมีปุ่ม **"Say Hello"** — คลิกแล้วมี dialog ขึ้น = SamplePlugin ทำงานถูกต้อง ✓

## ต่อไปสร้าง plugin ใหม่

```powershell
.\scripts\new-plugin.ps1 -Name MyFirstPlugin -Description "Trying things out"
```

อ่าน `docs/WORKFLOW.md` สำหรับรายละเอียดทุกอย่าง
