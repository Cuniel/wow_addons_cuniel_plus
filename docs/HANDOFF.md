# 当前开发交接

## 2026-10-21 发布执行快照（优先于下方历史阶段）

- 发布验收已完成：远程源码提交 `af3fea3be7090fd52e49deadc2780141ea7cec05`，Actions [39616014977](https://github.com/Cuniel/wow_addons_cuniel_plus/actions/runs/39616014977) success；[v0.3.21](https://github.com/Cuniel/wow_addons_cuniel_plus/releases/tag/v0.3.21) 正文与逐版说明一致，安装包实际下载通过 ZIP 完整性及全部 22 文件与 Git 源码逐字节比对。发布包 57,947 字节，SHA-256 `12a5f4345631e2222f6504f6c782ed8c468219f9d1d685f62fa70ad10ad75773`。没有真实游戏验收。
- 本地源码基准 HEAD `3e27c42443d7818bf6a5f16ec4f3c4da64cf7863`，远程源码树与本地一致：`9f1a9054ef5ee38c2ce6f0220beb05da0c9bc3cb`。由于 GitHub API 另建发布提交，本地与远程提交历史不同，不能直接把不同 SHA 视为代码丢失；本段交接验收随后作为单独文档提交同步，最新 HEAD 以 git log 和远程 main 为准。不得强推或重置以消除该差异；新设备从 GitHub clone 即可取得已发布功能。
- 本次追加修改已正常提交，原有源码/文档没有被清理；未跟踪的两张 docs/design UI 草图保留本地，未纳入仓库或安装包。接手时仍先核对 git status，勿把这两张资产认作已跨设备同步。
- 最新本地发布基准：`fc3c97a` 提交积累工作，`cfbf5ba` 正常合并远程 0.3.18 历史，合并结果树与已审阅 .21 一致。常规 push 因沙箱无法读取 Windows Credential Manager 而失败，没有推送成功；改用已连接的 GitHub API 同步同一源码树。API 创建提交与本地提交 SHA 可能不同，必须比较树内容，不强推、不重置本地提交。
- 用户随后反馈目标显隐跳动：相邻头像原来仅按水平重叠判断，导致血条外侧头像遗漏；已修正相邻间距并在隐藏时保留单位/子框障碍。新增回归在旧代码失败、新代码通过，后续全套复验。真实客户端待复测。没有修改其他插件源码或替换暴雪冷却/小组件全局函数。
- 用户已明确授权本次提交、推送与发布 0.3.21；未恢复跨会话长期自动发布授权。下方“未授权/未联网/未提交”是此前各阶段事实，不代表本次执行结果。
- 发布前分支 main，HEAD `84f9290cce425f9f0defab8a248e0af3d40369dd`；已联网 ls-remote 并 fetch，远程 main 确认为 `8f1ce204afda58ad65f25878df0bcf1d2f033d9e`，尚无 v0.3.21 标签。先提交本地积累工作，再正常合并远程历史，不 reset/clean/checkout/pull/rebase 或强推。
- 发布前工作区 12 个修改、14 个未跟踪，无暂存；所有源码、测试、文档与工作流改动均保留。两张本地 UI 草图继续保留为未跟踪文件，是否纳入仓库仍待确认，不属于发布安装包。没有上传任何原始 SavedVariables。
- 十个 tests/test_*.py 脚本和 tools/release_notes.py 于本次发布前再次通过。运行方法见下方及 DEVELOPMENT。模拟通过不代表 Mac/Windows 游戏通过。
- 本次准备发布 0.3.21，涵盖 0.3.19/0.3.20 尚未单独发布的增量；实际提交 SHA 以包含本段的提交及后续合并提交为准，远端发布状态应读取 Actions 和 v0.3.21 Release 核验，不能只凭本段认定成功。
- 发布过程中用户反馈 21:41“界面错误过多”。只读错误记录确认：21:41:46 场景任务追踪器 UpdateCooldown → CooldownFrame_Set 比较受限制 start，标记 execution tainted by ShestakUI，counter 1804（记录累计次数，不等于每秒频率）。同日 UIWidget 文本高度错误 counter 2273，VoidcoreHelper 物品提示参数错误 counter 23。上述栈无 Cuniel_plus，不能排除间接污染或据此认定唯一责任源；0.3.21 不含这些错误的修复。
- 下一步：对 ShestakUI 任务追踪/小组件美化做可逆对照，复现场景冷却/地图错误；单独禁用 VoidcoreHelper 验证物品提示错误。不要隐藏错误作为修复，也不要删除有效备份。数字统一覆盖仍为已确认优先需求。

## 以下为审计与开发阶段历史

快照日期：2026-10-21，Asia/Shanghai（审计与实现开始于 10-20）。先读 [AGENTS](../AGENTS.md)，再核对实际 Git；本文不是已同步或已通过游戏验收的证明。

## Git 基准与差异

- 分支 main，本地 HEAD：`84f9290cce425f9f0defab8a248e0af3d40369dd`，提交主题为 0.3.17 中文聊天备份/恢复。
- 缓存 origin/main：`8f1ce204afda58ad65f25878df0bcf1d2f033d9e`，主题为 0.3.18 分类设置和 Details 布局；本地分支相对该缓存落后一提交。
- 当前远程最新状态未经联网确认，本轮没有 fetch/pull、暂存、提交、推送或发布。
- 文档整理前，缓存提交所含 53 个文件与工作区比较：28 个字节一致，25 个仅换行不同，无内容差异/缺失。本轮文档修改后不能再称全部文件与缓存一致；本地未提交/未跟踪状态仍必须按 Git 判断。
- 整理开始 TOC 为 0.3.18；后续获授权功能代码当前为本地 0.3.21，schema 仍为 8（仅补新默认字段，无破坏迁移）。不能因版本不同于 HEAD 而覆盖工作区或称已同步。新文档/代码仍在本地，其他设备尚不能通过 GitHub 获得。

整理开始时无暂存；已有 9 个修改：

```text
.github/workflows/release.yml
CHANGELOG.md
Cuniel_plus/Core.lua
Cuniel_plus/Cuniel_plus.toc
Cuniel_plus/Options.lua
Cuniel_plus/README.md
README.md
docs/PRD.md
docs/SPEC.md
```

已有 6 个未跟踪文件：

```text
Cuniel_plus/Modules/DetailsLayout.lua
docs/design/settings-concept-a.png
docs/design/settings-concept-b.png
release-notes/v0.3.18.md
tests/test_details_layout.py
tests/test_options.py
```

其中 DetailsLayout、0.3.18 正文和两个测试存在于缓存提交，但相对本地 HEAD 仍是未跟踪；两张设计图仅本地。不要把所有这些都误归为本次新写功能。

## 当前任务与已完成阶段

文档标准化阶段只改九文档：AGENTS、根 README、docs 中 ARCHITECTURE/HANDOFF/DECISIONS/DEVELOPMENT/SPEC/PRD、随包 README。保留历史需求、版本说明和第 11 条长期授权原文，补齐架构、环境、交接，修正过期状态和操作入口。该阶段不改业务代码、依赖或工作流，实际验收记录见下。

用户随后明确授权：完成文档后继续修改三项问题的 Lua 与测试：Mac 字体偏小；Details 按可用高度上下分配，伤害 60%/治疗 40%，减少可见行数；战斗时统计窗进入中央视野。**没有授权 Git 提交、推送或发布。** 后续代码增量须与文档阶段分别记录，不再把九文件限制错误套用到已明确的新开发授权。

## 功能与验证状态

- 代码已存在：分类设置、部位品质/字号、物品缓存/过滤、中文聊天备份恢复、装等提示、背包增强、ESC、静默及 0.3.18 Details 原算法。
- 新设置窗口基础 820×590；图稿搜索、独立图标样例、恢复本页默认未实现。
- Details 当前本地 0.3.21：保留 0.3.20 四条测量边界，按用户确认以可用区右边界锚定治疗，伤害等宽紧邻左侧，2 UI 单位间距；不足则右对齐等宽堆叠（伤害下/治疗上，6:4 预算），不再拉宽铺满空白。保护、有限纠偏、总高度与原会话恢复保持；模拟通过，真实游戏仍待复测。
- 公会/密语/团队标题当前默认 14（独立 labelSize，10–20），不改正文和普通标签，适用 Windows/Mac；已有角色无重建，仅更新字体。ChatTabs 定向处理，Readability 让位避免争抢。开关/原标签恢复、悬停和战斗延后已有模拟。
- Mac 样本：此前报告 3600×2260；新图 UI 约 0.782、mult 约 0.50005、单位字号约 8.00079、标签约 9.00089。已核对上游高分辨率缩小字体和悬停重设标签的代码路径，新增定向补偿（默认仅 Mac、最低 12，可调 10–20），Windows 默认不变。悬停重设、恢复与战斗延后模拟通过；真实 Mac 效果未验，无渲染比例数据。
- 数字公共函数已有万/亿、K/M/B、跟随原插件；全面覆盖与完整数值模式仍优先待实现，不能宣称统一了 Details 或经验/声望独立路径。
- GearView 自身污染未可靠修复；独立部位文字不是修复其内部调用。战斗受保护窗口不能强制关闭。掉线未确定原因。团队施法条修复未纳入插件。
- 功能阶段重新读取本机 Windows Wow.exe，FileVersion/ProductVersion 均为 12.1.5.70448；Interface 120105，TOC 声明 120100/120105。不是 Mac 构建或游戏验收证明，未联网确认全球最新版本。

## 环境、验证与恢复

命令与平台限制见 [DEVELOPMENT](DEVELOPMENT.md)。Python 3.12 + requirements-dev 中 Lupa；tests/test_*.py 是独立模拟脚本，release_notes.py 默认只读，package.py 写 dist，--backfill 会远程写历史正文。

文档阶段验收（实际完成）：九文档本地 Markdown 链接均存在，敏感凭据模式和行尾空白扫描无命中；范围外 50 个项目文件 SHA-256 清单摘要前后相同（b78603f7826b7609b6e9fec6c94254d7426ccfa9d53155c78d81bd6b0cbbbf17），确认原有源码、工作流、未跟踪资产未被文档阶段修改。git status 为 10 个已修改、10 个未跟踪，无暂存，HEAD/缓存引用未变。普通 git diff --check 报原有工作流/Core/TOC 的六行 CRLF 空白；额外 git -c core.whitespace=cr-at-eol diff --check 通过，没有借机改这些文件。文档阶段未重新运行全套模拟、未打包或游戏验证，没有发布操作；后续功能任务另记实际结果。

配置迁移需保护有效备份并验证恢复；不清空 WTF，不记录秘密或上传原始 SavedVariables。聊天备份不含消息，Details 原位置只在会话内。跨设备不能依赖本机 work/dist、剪贴板图片或历史聊天恢复状态。

## 0.3.19 阶段记录（历史）

新增 Modules/Readability.lua；Core 补默认配置，TOC 加载；DetailsLayout 改右侧高度/行数、保护和有限外部纠偏；Options 增字体页和真实行为说明。test_details_layout.py、test_options.py 补充结果验证，保留原测试。版本、README、CHANGELOG、release-notes/v0.3.19.md 同步。本阶段没有修改上游文件、工作流、依赖或游戏安装目录。

十个现有脚本全部成功退出，相关 Lua 由现有检查编译；tools/release_notes.py 校验 0.3.19 通过。使用已存在的 work/lua-test-v038 中 Lupa 2.8，预先导入 lua51 避免旧搜索路径，不安装或升级依赖：

```sh
python -B -c "import sys,runpy;from pathlib import Path;sys.path.insert(0,'work/lua-test-v038');import lupa.lua51;[runpy.run_path(str(p),run_name='__main__') for p in sorted(Path('tests').glob('test_*.py'))]"
python -B tools/release_notes.py
```

该 work 路径是本机测试依赖，不是源码或跨设备前提，新设备依 DEVELOPMENT 建环境。覆盖混合缩放、6:4/整行、障碍/无空间、稳定坐标、原生鼠标松开、非保护战斗纠偏、保护等待、持续争抢停止/手动重试、脱战恢复，以及字体平台默认/较大字号保留/悬停/开关恢复。没有真实游戏、Mac 执行或 Actions 验证。

0.3.19 当时验收：tools/package.py 已生成 dist/Cuniel_plus-0.3.19.zip（54,682 字节、22 个文件），ZIP 完整性与关键源码逐字节比对通过；SHA-256 为 5724689bf6e313be4110c571f87b4bdef2ee86fa9091a405d4de64a719fa8668。九文档本地链接、敏感凭据模式和行尾空白扫描无问题，第 11 条历史原文仍在。当时 git status 为 10 个修改、12 个未跟踪，暂存为空；HEAD 和缓存引用保持上述值。git diff --check 返回 2，报告工作流/Core/TOC 的八行 CRLF（文档阶段原有六行，功能阶段新增两行）；按 cr-at-eol 规则检查返回 0。未批量归一化或修改 Git 配置。原工作流、已有 0.3.18 说明/两张设计图及其他无关源码保持，相关代码和测试是在原改动上继续增补。

本轮实际修改范围为九文档，以及后续获授权的 Core、TOC、Options、DetailsLayout、Readability、两个相关测试、CHANGELOG 和新增 v0.3.19 正文；本地包在忽略的 dist 内。Git 基准没有因此自动推进，尚无提交/推送/发布。建议功能提交主题（未执行）：`fix: improve high-DPI fonts and stack Details meters within the right column`；文档可单独审阅，暂不自动拆分或暂存。

## 0.3.20 阶段记录

当前 0.3.20 任务（2026-10-21）：已按用户四边界反馈调整 DetailsLayout 及测试，Options 和 TOC 更新 0.3.20，README/随包说明/CHANGELOG/v0.3.20 正文与 SPEC/PRD/架构/决策同步。没有改变字体模块、Core 配置、依赖、工作流或其他插件。取消视口比例假设，目标隐藏仍读取框体锚点；必要坐标不可访问时等待。初始可读宽度用于并排判定，防止自身调整后反复切换模式。

十个测试脚本已全部成功退出，新增覆盖四边界、双图标宽度、底部线、宽窄自动切换、两窗等宽、总高度、隐藏/受限制目标、不同有效缩放、实际按钮与无形占位框、拖动/战斗/恢复。混合缩放测试允许 0.001 UI 单位的浮点舍入误差。真实游戏未验证，不能把该结果当作用户截图已修复。

发布说明校验通过；本地 dist/Cuniel_plus-0.3.20.zip 已生成，22 个文件、56,705 字节，ZIP 完整性和包内全部文件与当前源码逐字节比对通过；SHA-256 为 11b0f8f0c5777f4e4808932ba5add8e30f6628fd963232925556d526f23605b5。原 0.3.19 包哈希保持，未覆盖。客户端 2026-10-21 重新读取 Windows Wow.exe，仍为 12.1.5.70448。

本任务范围外 49 个项目文件的 SHA-256 清单摘要前后一致（c4884db78f4fc8973fed1b3a954d92fcab1f6ea956b1dda5feb3d3793db1bfb0），原有无关改动/资产保留；文档本地链接与凭据模式扫描通过。Git 仍为上述 main/HEAD/缓存引用，10 个修改、13 个未跟踪、暂存为空；远程最新状态未联网确认，没有同步、提交、推送或发布。普通 diff --check 仍报八行原有 CRLF，按 cr-at-eol 检查通过。建议提交主题（未执行）：`fix: constrain Details layout to measured UI bounds`。

## 0.3.21 当前任务与验证

0.3.21 最新增量：用户明确三个中文标签标题默认 14，并确认统计以可用区右界锚定。修改 Core 的新默认字段、ChatTabs 标题管理及 Readability 让位、Options 独立字号、Details 右锚与 2 UI 间距；相关测试及版本文档同步。没有重建已有角色标签、覆盖备份、改聊天正文、动上游或依赖/工作流，也没有 Git 写入授权。

十个模拟脚本通过：新增标题默认14/正文13保持、悬停重设、无需重建、独立字号、战斗延后、通用字号18不覆盖标题14与关闭恢复，以及统计右界/贴合间距/保留宽度/堆叠右边一致的断言。真实游戏验证未完成。

发布说明校验与打包完成：dist/Cuniel_plus-0.3.21.zip，22 文件、57,901 字节，完整性及包内全部文件与源码逐字节核对通过，SHA-256 为 5a4e698f274537ee2a75f90a32c110080056d34588ad04a1755bec5788dc0148。原 0.3.20 ZIP 哈希保持。文档本地引用和凭据模式扫描通过；普通 diff --check 报九处 CRLF，按 cr-at-eol 检查通过。Git 分支/HEAD/缓存引用不变，12 个修改、14 个未跟踪，暂存为空；没有同步、提交、推送或发布，远程最新状态仍未联网确认。

建议提交主题（未执行）：`fix: size Chinese chat captions independently and right-anchor Details meters`。SSH clone 不能自动获得这些尚未提交的本地增量，应先由用户明确授权同步；当前没有恢复长期发布授权。

## 下一步与待确认事项

1. 请用户安装本地 0.3.21，复测三个标题字号、悬停/开关/正文保留、Details 右锚/紧邻及原四边界/战斗；不能仅凭模拟称全部完成。数字扩展保持已确认优先级。
2. 接手先核对 main、HEAD、缓存与实际工作区，确定本地修改保护方案；不要自动 reset、checkout、pull/rebase 或清理未跟踪文件。联网与跨设备同步应另获授权，不能将本文视为已同步。
3. GitHub 是交接统一基准；确认允许提交/推送后才能让其他设备通过 GitHub 获取这些本地成果。当前仅提供建议 commit message：`docs: document architecture and cross-platform handoff`，没有执行。
4. 长期发布规则待确认：原 AGENTS 第 11 条包含“用户已授权本仓库的提交与自动发布，无需为每次常规提交再次请求业务确认”。建议改为“提交、推送和发布须有当前任务明确授权，授权范围内不重复询问”；影响是停止跨会话默认沿用旧授权，不改变获授权推送后的 Actions 自动发布机制。原条文未改，当前用户禁止操作优先。
5. 根 LICENSE 和上游排序代码许可依据尚未确认；设计图是否纳入后续提交也待确认，不阻塞本轮文档整理。不得为了补齐文档编造许可或发布验证记录。
