# 开发环境与验证

更新于 2026-10-20。所有命令从仓库根目录（含 Cuniel_plus、tests、tools）执行。命令存在不代表本轮已执行；实际结果见 [HANDOFF](HANDOFF.md)。

## 环境与依赖

需要 Git、Python；建议 Python 3.12，与现有 CI 一致。requirements-dev.txt 仅声明 `lupa>=2.0,<3`，测试使用 lupa.lua51，无精确锁文件。无 Node/npm、数据库或后端服务。ShestakUI/Bagnon/BagBrother/Details 是功能可选集成，不是 Python 模拟的依赖。真实游戏验证需要 Windows/macOS 正式服；Cloud/Ubuntu 不能代替客户端。

虚拟环境建议放在仓库旁，避免当前没有忽略的 .venv 被误提交。已有有效环境不要覆盖。先确认所用解释器版本。

Windows PowerShell：

```powershell
python --version
python -m venv ../cuniel-plus-venv
& ../cuniel-plus-venv/Scripts/Activate.ps1
python -m pip install -r requirements-dev.txt
```

macOS / Ubuntu：

```sh
python3 --version
python3 -m venv ../cuniel-plus-venv
. ../cuniel-plus-venv/bin/activate
python -m pip install -r requirements-dev.txt
```

安装需要相应网络权限。全新 macOS/Ubuntu/Cloud 安装本轮未实际验证；不同 CPU 架构的 Lupa wheel 或编译条件需现场确认。PowerShell 激活受限时可直接用环境内 python，不必修改全局执行策略。运行时不需要 .env 或 API Key，CI 的 GH_TOKEN 由 GitHub 提供，不能写个人凭据进文件。

## 接手时只读核对

```sh
git status --short --branch
git rev-parse HEAD
git rev-parse origin/main
git log -5 --oneline
```

origin/main 是缓存，不证明远程最新。未经当前授权不自动同步、暂存、提交、推送或发布，不覆盖用户工作区。接手阅读顺序见 AGENTS。

## 模拟验证与打包

单项示例：

```sh
python -B tests/test_details_layout.py
python -B tests/test_options.py
python -B tools/release_notes.py
```

完整脚本集（PowerShell/POSIX，非 pytest）：

```sh
python -B -c "import lupa.lua51, runpy; from pathlib import Path; [runpy.run_path(str(p), run_name='__main__') for p in sorted(Path('tests').glob('test_*.py'))]"
python -B tools/release_notes.py
```

先导入 lupa.lua51 可使该批量命令使用当前环境的依赖。部分旧脚本仍插入 work/lua-test-v036 搜索路径，单项运行需留意解释器/依赖来源，不能以旧 work 副本为权威源码。十个现有脚本覆盖窗口、聊天、Details、设置、部位、装等、物品缓存/过滤、发布说明；一些也编译 Lua。发布测试含构建号常量，未来客户端升级需同步核对。

一般开发获得相应授权后本地打包：

```sh
python -B tools/package.py
```

输出 dist/Cuniel_plus-<TOC版本>.zip。脚本会写 dist，递归打包源码目录，无精细白名单；不要在 Cuniel_plus 放临时资料。模拟通过不能证明真实安全执行、字体、吸附组或战斗效果。

release_notes.py 默认只校验，**--backfill 会调用 gh 修改远程历史 Release**。当前工作流监听主分支源码、tests、tools、release-notes、根 README、CHANGELOG 和自身路径；文档推送也可能创建或更新 Release。未获当前授权不执行这些操作，文档整理阶段不运行打包或依赖安装。

## 游戏运行、调试和数据恢复

安装到实际正式服 `_retail_/Interface/AddOns/Cuniel_plus`，启用并 /reload；不写死平台盘符或用户名，不清空 WTF。/cuniel、/cplus 打开设置。/cplusesc 查看窗口/战斗状态，/cplusdiag 查看已捕获拦截，插件名不是唯一根因证明。记录客户端/插件版本和首条错误堆栈、时间与复现步骤，日志先脱敏。

配置迁移测试先退出游戏，保护原有效备份并明确恢复路径；客户端运行时编辑 SavedVariables 可能被退出写回覆盖。聊天备份只恢复设置，不含聊天内容；Details 原位置备份仅当前会话。不能上传原始账号配置或以删除 WTF 代替修复。

客户端记录为 2026-10-19 国服 12.1.5.70448 / Interface 120105，TOC 同时声明 120100。后续发版须重新核对实际 Wow.exe、active wow 安装元数据，必要时游戏 GetBuildInfo，不以美服更新时间推断。

## 平台与常见问题

| 环境 | 当前证据与验证边界 |
| --- | --- |
| Windows | 本轮审计平台；历史测试和用户反馈须与本轮执行结果区分 |
| macOS | 用户报告 3600×2260，截图 UI 约 0.782；有字体偏小与 Details 遮挡反馈，尚无本轮实际执行记录 |
| Ubuntu | 工作流 ubuntu-latest / Python 3.12，本轮未触发或联网核对 CI |
| Codex Cloud | 可做模拟/打包，没有专用 setup 配置，尚未实际验证；不可运行 WoW 验收 |

文件大小写/TOC 拼写需适配 Linux。当前 core.autocrlf=true，无 .gitattributes，不为文档任务批量归一化源码换行。git diff --check 报 CRLF 时区分原有差异，可额外 `git -c core.whitespace=cr-at-eol diff --check`，不能借机改配置或源码。

依赖错误先查当前 python 和 lupa.lua51.__file__，不擅自升级或删除旧环境。界面未更新先核对实际安装目录与版本；数量缺失先查登录/银行采集与过滤；ESC 战斗中失败先脱战核对。Mac Details 最新 6:4/行数及字体补偿已在本地 0.3.19 通过模拟，游戏待验，仍须按反馈追踪实际移动路径，不把截图当成已定位唯一根因。
