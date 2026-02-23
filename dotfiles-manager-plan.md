# Dotfiles Manager: CLI Tool Design

## Overview

一个基于 Bare Git Repo 的 PowerShell 7 Module，提供类似 `git` 的交互式管理体验，用于跟踪和版本控制 Home Folder 中的重要配置文件。

**定位**：个人配置备份工具，Windows 平台，通过 OneDrive 实现跨设备同步。

**核心理念**：
- Git 提供版本历史和回滚能力
- OneDrive 提供跨设备同步和云备份
- Bare repo 放在 OneDrive 路径下，自动获得备份能力

---

## 技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 运行时 | PowerShell 7 (pwsh) | 现代语法、跨平台基础 |
| 安装方式 | PowerShell Module (.psm1) | Tab completion、正式的模块管理 |
| 底层存储 | Bare Git Repo | 文件原地管理，无 symlink |
| 同步方式 | OneDrive（bare repo 放 OneDrive 路径下） | 零配置同步，不依赖 git remote |
| 文件夹跟踪 | 自动跟踪（config 记录 tracked folders） | 新文件自动纳入管理 |
| 管理目录 | `~/.dotfiles/`，由 bare repo 跟踪自身 | 工具本身也被版本控制和备份 |

---

## Command Design

### 命令一览

| 命令 | 说明 | Phase |
|------|------|-------|
| `dot init` | 交互式初始化 bare repo 和配置 | MVP |
| `dot add <path>` | 添加文件/文件夹到跟踪（仅 staging） | MVP |
| `dot remove <path>` | 从跟踪列表移除（不删除源文件） | MVP |
| `dot list` | 列出所有被跟踪的文件 | MVP |
| `dot status` | 查看哪些跟踪文件有变更 | MVP |
| `dot diff [path]` | 查看具体变更内容 | MVP |
| `dot commit [message]` | 提交当前所有变更 | MVP |
| `dot restore [path]` | 恢复文件到最新已提交版本 | MVP |
| `dot log [n]` | 查看提交历史 | MVP |
| `dot doctor` | 健康检查 | MVP |
| `dot help` | 显示帮助信息 | MVP |
| `dot sync` | 一键 auto-commit（用于定时任务） | Phase 2 |
| `dot schedule` | Task Scheduler 注册 | Phase 2 |
| `dot push` | 推送到远程仓库 | 可选 |
| `dot pull` | 从远程拉取 | 可选 |
| `dot remote <url>` | 设置远程仓库地址 | 可选 |

### 命令详细行为

#### `dot init`

交互式向导，逐步引导用户完成初始化。

```
dot init

╭─ Dotfiles Manager Setup ─────────────────────╮

[1/3] Bare repo 存储位置?
  › C:\Users\ruilin.liu\OneDrive\repos\dotfiles.git  (推荐，OneDrive 备份)
    D:\repos\dotfiles.git
    自定义路径...

[2/3] 确认 Work Tree (Home 目录):
    C:\Users\ruilin.liu

[3/3] 立即添加常用配置文件?
  ☑ .gitconfig
  ☑ .claude/
  ☐ .ssh/config
  ☐ AppData\Local\nvim/
  ☐ 跳过，稍后手动添加

╰───────────────────────────────────────────────╯

行为：
1. 交互选择 bare repo 路径（提供推荐选项 + 自定义）
2. 创建 bare repo（git init --bare）
3. 设置 status.showUntrackedFiles no
4. 创建 ~/.dotfiles/ 管理目录
5. 生成 config.json
6. 创建默认 .gitignore
7. 扫描 Home 目录下常见配置文件，让用户勾选
8. 将选中的文件 git add 并初始 commit
9. 将 .dotfiles/ 自身加入跟踪

输出：
✓ Bare repo created at C:\Users\ruilin.liu\OneDrive\repos\dotfiles.git
✓ Config saved to ~/.dotfiles/config.json
✓ Tracking 3 paths (8 files)
✓ Initial commit created
✓ Ready! Run 'dot add <file>' to start tracking more files.
```

也支持非交互模式（用于脚本/自动化）：
```
dot init -RepoPath "C:\OneDrive\repos\dotfiles.git" -NoInteractive
```

#### `dot add <path>`

```
dot add ~/.claude                     # 添加整个文件夹
dot add ~/profile.local.ps1           # 添加单个文件
dot add ~/.ssh/config ~/.gitconfig    # 添加多个文件

行为：
1. 解析路径（支持 ~ 和相对路径）
2. 安全检查：拒绝添加匹配 excludePatterns 的文件（-Force 可强制）
3. 大文件检查（>1MB 警告确认）
4. 如果是文件夹，递归添加所有内容，并记录到 config.json 的 trackedFolders
5. 执行 git add（仅 staging，不自动 commit）

输出：
✓ Staged: .claude\CLAUDE.md
✓ Staged: .claude\settings.json
  2 files staged. Run 'dot commit' to save.

文件夹添加时：
✓ Staged: .claude\ (2 files)
  Folder registered for auto-tracking.
  New files in .claude\ will be automatically included in future commits.
```

#### `dot remove <path>`

```
dot remove ~/.ssh/config
dot remove ~/.claude                  # 移除整个文件夹的跟踪

行为：
1. 执行 git rm --cached（只取消跟踪，不删除源文件）
2. 如果是 trackedFolders 中的文件夹，从列表移除

输出：
✓ Untracked: .ssh\config (file preserved on disk)
  Run 'dot commit' to save.
```

#### `dot status`

```
行为：
1. 对 trackedFolders 中的文件夹执行 git add（纳入新文件）
2. 运行 git status --porcelain
3. 格式化输出，分类显示

输出：
Dotfiles Status
───────────────
Modified:
  M  .claude\CLAUDE.md
  M  profile.local.ps1

Deleted:
  D  .config\old-tool\config.yaml

New (auto-tracked):
  +  .claude\new-file.md

2 modified, 1 deleted, 1 new
```

#### `dot diff [path]`

```
dot diff                              # 所有变更
dot diff ~/.claude/CLAUDE.md          # 特定文件

行为：执行 git diff，对已跟踪文件显示差异
输出：标准 git diff 输出（带颜色）
```

#### `dot commit [message]`

```
dot commit                            # 自动生成 message
dot commit "update claude config"     # 自定义 message

行为：
1. 对 trackedFolders 执行 git add（纳入新文件）
2. git add -u（已跟踪文件的变更）
3. 如果无 message，自动生成: "update: file1, file2 @ 2025-01-15 14:30"
4. 执行 git commit

输出：
✓ Committed: "update: CLAUDE.md, profile.local.ps1 @ 2025-01-15 14:30"
  2 files changed, 15 insertions(+), 3 deletions(-)
```

#### `dot restore [path]`

```
dot restore                           # 恢复所有文件到最新 commit
dot restore ~/.claude/CLAUDE.md       # 恢复单个文件

行为（无参数）：
1. 警告会丢失所有未提交变更
2. 要求 [y/N] 确认
3. git checkout -- .

行为（有参数）：
1. git checkout -- <file>

输出：
# 无参数
⚠  This will overwrite ALL local changes with the last committed version.
   Continue? [y/N] y
✓ Restored 5 files to last committed version

# 有参数
✓ Restored: .claude\CLAUDE.md
```

#### `dot log [n]`

```
dot log                               # 最近 20 条
dot log 50                            # 最近 50 条

输出：
a1b2c3d  2h ago    update: CLAUDE.md, profile.local.ps1
e4f5g6h  1d ago    track: .claude (2 files)
i7j8k9l  3d ago    init: dotfiles setup
```

#### `dot doctor`

```
行为：检查工具运行状态，诊断常见问题

输出：
Dotfiles Doctor
───────────────
✓ git found: git version 2.43.0
✓ PowerShell: 7.4.1
✓ Bare repo exists: C:\Users\ruilin.liu\OneDrive\repos\dotfiles.git
✓ Config valid: ~/.dotfiles/config.json
✓ Tracked: 15 files across 4 folders
✗ 1 tracked file missing from disk:
    .config\old-tool\config.yaml
⚠ Repo path is NOT in OneDrive (no cloud backup)
```

#### `dot help`

```
行为：显示所有命令的用法摘要

输出：
Dotfiles Manager — Track and version your config files

Commands:
  dot init                  Interactive setup wizard
  dot add <path>            Stage files/folders for tracking
  dot remove <path>         Untrack files (keeps on disk)
  dot list                  List all tracked files
  dot status                Show pending changes
  dot diff [path]           Show file differences
  dot commit [message]      Commit staged changes
  dot restore [path]        Restore files to last commit
  dot log [n]               View commit history
  dot doctor                Health check
  dot help                  This help message
```

---

## Project Structure

```
~/.dotfiles/                         ← 管理目录（由 bare repo 跟踪自身）
├── DotfilesManager/                 ← PowerShell Module
│   ├── DotfilesManager.psd1        ← Module manifest
│   ├── DotfilesManager.psm1        ← Module 主文件（加载所有组件）
│   ├── Public/                      ← 导出的命令
│   │   └── Invoke-Dot.ps1          ← dot 命令主入口 + 路由
│   ├── Commands/                    ← 各子命令实现
│   │   ├── Init.ps1
│   │   ├── Add.ps1
│   │   ├── Remove.ps1
│   │   ├── Status.ps1
│   │   ├── Diff.ps1
│   │   ├── Commit.ps1
│   │   ├── Restore.ps1
│   │   ├── Log.ps1
│   │   ├── List.ps1
│   │   ├── Doctor.ps1
│   │   └── Help.ps1
│   └── Private/                     ← 内部函数
│       ├── Git.ps1                  ← bare git 操作封装
│       ├── Config.ps1               ← config.json 读写
│       ├── Security.ps1             ← 安全检查（敏感文件拦截）
│       └── Format.ps1               ← 输出格式化
├── config.json                      ← 运行时配置
└── install.ps1                      ← 安装脚本（注册 Module + alias）
```

### PowerShell Module 注册

安装后用户可以直接使用 `dot` 命令：

```powershell
# install.ps1 做的事情：
# 1. 将 DotfilesManager 模块链接/复制到 $env:PSModulePath
# 2. 在 $PROFILE 中添加 alias: Set-Alias -Name dot -Value Invoke-Dot
# 3. 注册 ArgumentCompleter（tab completion）
```

### config.json

```json
{
  "version": "1.0",
  "repoPath": "C:\\Users\\ruilin.liu\\OneDrive\\repos\\dotfiles.git",
  "workTree": "C:\\Users\\ruilin.liu",
  "trackedFolders": [
    ".claude",
    "AppData\\Local\\nvim"
  ],
  "excludePatterns": [
    "*.pem", "*.key", "*.pfx", "*.p12",
    "id_rsa", "id_ed25519",
    "*.env", ".env.*",
    "*secret*", "*token*", "*credential*", "*password*"
  ]
}
```

**字段说明**：
- `repoPath`: bare git repo 路径，推荐放 OneDrive 下
- `workTree`: 工作目录，即 Home 目录
- `trackedFolders`: 用户添加的文件夹路径，新文件会自动纳入跟踪
- `excludePatterns`: 安全拦截规则，匹配的文件禁止添加

注意：不维护 `trackedPaths` 文件列表——以 `git ls-files` 为唯一真实来源。`trackedFolders` 仅记录需要自动扫描新文件的文件夹。

---

## 核心模块设计

### Private/Git.ps1 — Bare Git 封装

```powershell
function Invoke-DotGit {
    param(
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )
    $config = Get-DotConfig
    & git --git-dir=$config.repoPath --work-tree=$config.workTree @Arguments 2>&1
}

function Get-DotStatus   { Invoke-DotGit status --porcelain }
function Get-DotTracked  { Invoke-DotGit ls-files }
function Get-DotDiff     { param($Path) if ($Path) { Invoke-DotGit diff -- $Path } else { Invoke-DotGit diff } }

# 对 trackedFolders 中的文件夹执行 git add（自动跟踪新文件）
function Update-TrackedFolders {
    $config = Get-DotConfig
    foreach ($folder in $config.trackedFolders) {
        $fullPath = Join-Path $config.workTree $folder
        if (Test-Path $fullPath) {
            Invoke-DotGit add $folder
        }
    }
}
```

### Private/Security.ps1 — 安全拦截

```powershell
function Test-PathSafe {
    param([string]$Path, [switch]$Force)
    $config = Get-DotConfig
    $issues = @()

    # 排除模式检查
    foreach ($pattern in $config.excludePatterns) {
        if ((Split-Path $Path -Leaf) -like $pattern -or $Path -like $pattern) {
            $issues += "Matches exclude pattern: $pattern"
        }
    }

    # 大文件检查
    $item = Get-Item $Path -ErrorAction SilentlyContinue
    if ($item -and -not $item.PSIsContainer -and $item.Length -gt 1MB) {
        $issues += "File too large: $([math]::Round($item.Length/1MB, 1))MB"
    }

    if ($issues -and -not $Force) {
        return @{ Safe = $false; Issues = $issues }
    }
    return @{ Safe = $true; Issues = @() }
}
```

---

## 典型工作流

### 首次安装

```powershell
# 1. Clone 工具本身（或直接下载）
git clone <repo> ~/.dotfiles

# 2. 运行安装脚本
~/.dotfiles/install.ps1

# 3. 交互式初始化（选择 repo 位置、勾选常见配置文件）
dot init

# 4. Done! 后续日常使用 dot 命令
```

### 日常使用

```powershell
# 编辑了一些配置文件...

# 查看哪些文件变了
dot status

# 查看具体改了什么
dot diff

# 提交
dot commit "tweak powershell aliases"

# 或者一步到位（Phase 2）
dot sync
```

### 添加新文件

```powershell
# 开始使用新工具，想跟踪配置
dot add ~/.config/starship.toml
dot add ~/AppData/Local/nvim      # 文件夹 → 自动跟踪新文件

# 确认已跟踪
dot list

# 提交
dot commit "track: starship + nvim config"
```

### 误改文件恢复

```powershell
# 恢复单个文件
dot restore ~/.claude/CLAUDE.md

# 恢复所有文件（需确认）
dot restore
```

### 健康检查

```powershell
dot doctor
```

---

## Error Handling & Edge Cases

| 场景 | 处理方式 |
|------|----------|
| `dot add` 敏感文件 | 拦截并提示，需 `-Force` 强制添加 |
| `dot add` 大文件 (>1MB) | 警告并要求确认 |
| `dot restore` 有未提交变更 | 警告会丢失变更，要求 `[y/N]` 确认 |
| 跟踪的文件被删除 | `dot status` 中显示为 Deleted |
| bare repo 不存在 | 提示运行 `dot init` |
| git 不在 PATH | 报错并给出安装指引 |
| config.json 损坏 | `dot doctor` 检测并提示修复 |
| 文件夹中有 `.git` 子目录 | 警告可能产生嵌套 repo 问题 |
| OneDrive 路径不存在 | init 时提示选择其他路径 |
| 重复 `dot init` | 检测已有 repo，提示是否重新配置 |

---

## Implementation Priority

### Phase 1 — MVP（核心版本控制）

基础设施：
- [ ] PowerShell Module 骨架（.psd1 / .psm1）
- [ ] `Private/Git.ps1` — bare git 封装
- [ ] `Private/Config.ps1` — config.json 读写
- [ ] `Private/Security.ps1` — 安全检查
- [ ] `Private/Format.ps1` — 输出格式化
- [ ] `install.ps1` — 安装脚本

命令：
- [ ] `dot init` — 交互式初始化向导
- [ ] `dot add` / `dot remove` — 管理跟踪文件
- [ ] `dot list` / `dot status` — 查看状态
- [ ] `dot diff` — 查看差异
- [ ] `dot commit` — 提交变更
- [ ] `dot restore` — 恢复文件
- [ ] `dot log` — 查看历史
- [ ] `dot doctor` — 健康检查
- [ ] `dot help` — 帮助信息

### Phase 2 — 自动化

- [ ] `dot sync` — 一键 auto-commit
- [ ] `dot schedule` — Task Scheduler 集成
- [ ] sync.log 日志记录

### Phase 3 — 体验优化

- [x] Tab completion (ArgumentCompleter)
- [x] 彩色输出优化
- [x] `dot diff` 语法高亮
- [x] `dot log` 美化格式

### Phase 4 — 可选：远程同步

- [ ] `dot push` / `dot pull` / `dot remote` — git remote 操作
- [ ] 冲突处理

### Phase 5 — 高级功能

- [ ] `dot encrypt` — git-crypt / age 加密集成
- [ ] `dot snapshot` — 手动打 tag 做快照
- [ ] PSGallery 发布
