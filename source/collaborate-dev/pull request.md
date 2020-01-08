# pull request

```text
作者: kiki
日期: 2020/1/7
```

## 目的

pull request(github) / merge request(gitlab)

- 从另外一个分支拉取修改
- fork 到当前分支，并且合并与现有代码的修改

## 流程

- fork 原仓库，相当于拷贝一份代码
- clone 到本地，**新建分支(有意义的名字)**，修改错误或添加功能特性
- 提交到 github/gitlab
- 在 github/gitlab 切换到新分支，发起 pull/merge request
- 原仓库管理员审核代码(代码风格、功能正常等)，决定是否合并到原仓库
  - 可以就指定 pull/merge request 发起讨论
- **每次新建分支开发之前先拉取原始仓库代码，更新**

| 操作项/填写项 | 说明 |
| --- | --- |
| Title | 标题。没有特殊要求保持默认即可 |
| Description | 描述。需要将变更的需求描述清楚，最好附件 Code Review 要点。**可选择模板** |
| Assignee | 分配人。被分配到的人将会收到邮件通知，跟 Merge 权限没有必然关系，仍然是项目的 Maintainers(Masters) 角色拥有 Merge 权限 |
| Milestone | 里程碑。【可选】 |
| Label | 标签。【可选】 |
| Source branch | 源分支。跟上一步骤选择一致，这里主要用于确认 |
| Target branch | 目标分支。跟上一步骤选择一致，这里主要用于确认 |

## patch 文件

`git am` 可将一个 patch 文件合并到当前代码。

github 为每个 PR 自动生成一个 patch 文件。下载该文件，合并到本地代码，就可在本地查看效果。

```sh
# -L 表示如果有 302 重定向，curl 会自动跟进
curl -L http://github.com/cbeust/testng/pull/17.patch | git am
curl https://github.com/sclasen/jcommander/commit/bd770141029f49bcfa2e0d6e6e6282b531e69179.patch | git am
```

## IDE MR 插件

- 创建 GitLab Access Token：菜单 `User Settings`->`Access Tokens`，进入 `Access Token` 添加页
  - **注意：**创建完成后，暂时保存 token。因为一旦刷新或者重开页面，token 就不可见了。

  | 项 | 说明 |
  | --- | ---- |
  | Name | 名称 |
  | Expires at | 过期时间，最远可以选择到 10 年后，根据需要填写 |
  | Scopes | 范围，这里选择 api 就够用了 |

- JetBrains：提供了诸多 IDE：IntelliJ IDEA、PyCharm、PhpStorm、WebStorm、RubyMide、AppCode、CLion、GoLand、DataGrip、Rider、Android Studio 等等，如无意外，都适用 gitlab 插件。
  - 安装两个插件即可：[Gitlab Projects](https://plugins.jetbrains.com/plugin/7975-gitlab-projects) 和 [Gitlab Integration](https://plugins.jetbrains.com/plugin/7319-gitlab-integration)
- Visual Studio：[GitLab Extension for Visual Studio](https://marketplace.visualstudio.com/items?itemName=MysticBoy.GitLabExtensionforVisualStudio)
- Visual Studio Code：[Gitlab MR](https://marketplace.visualstudio.com/items?itemName=jasonn-porch.gitlab-mr)
- Atom：[Gitlab](https://atom.io/packages/gitlab)

## 资料

- [Pull request vs Merge request](https://stackoverflow.com/questions/22199432/pull-request-vs-merge-request)
- [关于 pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests)
- [Merge request](http://192.168.1.36/help/user/project/merge_requests/index.md)
- [git 命令创建 MR](http://192.168.1.36/help/user/project/merge_requests/index.md#git-push-options)
