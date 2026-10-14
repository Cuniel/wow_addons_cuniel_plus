# Cuniel_plus

魔兽世界正式服的独立界面增强插件，主要配合 ShestakUI 使用。

当前版本：0.3.9。

## 安装

将仓库中的 `Cuniel_plus` 文件夹放到 `_retail_/Interface/AddOns/`，然后重新登录或 `/reload`。输入 `/cuniel` 或 `/cplus` 打开设置。

## 本次更新

- 背包装备部位字号可调：8–24，默认 11，即时生效、账号共用。
- ESC 关闭兼容：世界地图及角色、声望、货币分页。

历史功能和变更见 [插件说明](Cuniel_plus/README.md)。窗口关闭兼容是绕开已有污染调用的处理，ShestakUI 自身的其他客户端兼容错误仍需上游修复。已完成模拟测试，游戏实际效果需要登录验证。

## 验证与打包

安装 Python 及 `lupa` 后，运行 `python tests/test_slotlabels.py`、`python tests/test_windows.py`。运行 `python tools/package.py` 生成安装包。每次修改应先验证、再提交，保留可回退的版本历史。

## 自动发布

提交到 `main` 后，GitHub Actions 会先测试，再按 TOC 中的版本号打包并创建 Release。安装包可从仓库 Releases 下载。发布新版本时需递增 `Cuniel_plus/Cuniel_plus.toc` 的版本号；已有版本不会被覆盖。
