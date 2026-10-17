# Cuniel_plus

魔兽世界正式服的独立界面增强插件，主要配合 ShestakUI 使用。

当前版本：0.3.14。

## 安装

将仓库中的 `Cuniel_plus` 文件夹放到 `_retail_/Interface/AddOns/`，然后重新登录或 `/reload`。输入 `/cuniel` 或 `/cplus` 打开设置。

## 本次更新

- 物品提示新增各角色持有数量（职业颜色）及战团银行数量；独立缓存，无需启用 Bagnon。角色需登录、银行需打开后更新；运行时有 BrotherBags 数据时可导入。统计背包、身上装备、已读取个人银行和战团银行，不含邮箱或公会银行。

- 补上现代飞行地图和旧式路线图的 ESC 登记。新增 `/cplusesc` 查看加载版本、兼容开关和当前窗口的登记状态。

- ESC 兼容扩展到天赋/专精/法术书、专业、收藏、冒险指南、成就、观察、地下城查找器、好友、社区和宏窗口，并支持按需加载。

- 装等合并到原鼠标提示框，沿用 ShestakUI 标题与颜色，并防止重复追加。
- 装等重复提示修复按钮：切换当前 ShestakUI 配置为 Cuniel_plus 装等显示，重载生效。

- 背包装备部位字号可调：8–24，默认 11，即时生效、账号共用。
- ESC 关闭兼容：世界地图及角色、声望、货币分页。

历史功能和变更见 [插件说明](Cuniel_plus/README.md)。窗口关闭兼容是绕开已有污染调用的处理，ShestakUI 自身的其他客户端兼容错误仍需上游修复。已完成模拟测试，游戏实际效果需要登录验证。

## 验证与打包

安装 Python 及 `lupa` 后，运行 `python tests/test_slotlabels.py`、`python tests/test_windows.py`。运行 `python tools/package.py` 生成安装包。每次修改应先验证、再提交，保留可回退的版本历史。

## 自动发布

提交到 `main` 后，GitHub Actions 会先测试，再按 TOC 中的版本号打包并创建 Release。安装包可从仓库 Releases 下载。发布新版本时需递增 `Cuniel_plus/Cuniel_plus.toc` 的版本号；已有版本不会被覆盖。
