# Changelog 模板

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## 指导原则

- 记住日志是写给人的，而非机器。
- 每个版本都应该有独立的入口。
- 同类改动应该分组放置。
- 版本与章节应该相互对应。
- 新版本在前，旧版本在后。
- 应包括每个版本的发布日期。
- 注明是否遵守[语义化版本格式](https://semver.org/).

## 变动类型

- `Added` 新添加的功能
- `Changed` 对现有功能的变更
- `Deprecated` 已经不建议使用，准备很快移除的功能
- `Removed` 已经移除的功能
- `Fixed` 对 bug 的修复
- `Security` 对安全的改进

## 降低维护 ChangeLog 的代价

在文档最上方提供 `Unreleased` 区块以记录即将发布的更新内容。

- 大家可以知道在未来版本中可能会有哪些变更
- 在发布新版本时，可以直接将 `Unreleased` 区块中的内容移动至新发布版本的描述区块

## ChangeLog 模板

```md
# Changelog

## [Unreleased]

## [1.0.0] - 2017-06-20

## [0.0.1] - 2014-05-31

### Added

- item 1
- item 2

### Changed

### Deprecated

### Removed

### Fixed

### Security
```

## 其他工具

- [Node 环境的日志工具](https://github.com/conventional-changelog/conventional-changelog)
- [在 Go 实现更新日志生成](https://github.com/git-chglog/git-chglog)
