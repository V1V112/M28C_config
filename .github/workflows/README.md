# 本地保留已忽略文件

`.gitignore` 默认不会取消 Git 对已有文件的跟踪。本仓库使用本地
`pre-commit` 钩子，在提交前对新匹配忽略规则的文件执行
`git rm --cached`：文件会从 Git/GitHub 当前版本中删除，但本地实体文件保留。

首次克隆后运行：

```bash
git config core.hooksPath .githooks
```

云端的 `sync-gitignore.yml` 现在只负责检查，不再自动提交删除操作。这样可避免
云端先生成删除提交，随后本地 `git pull` 时把本地文件一起删除。

如果不使用钩子，也可以在提交 `.gitignore` 后手动执行：

```bash
git rm --cached -- 文件路径
git commit --amend --no-edit
```

目录使用 `git rm -r --cached -- 目录路径`。上述命令只取消跟踪，不删除工作区
文件。需要重新上传时，从 `.gitignore` 删除相应规则，再正常 `git add` 和提交。

注意：其他已经克隆过仓库的设备若尚未取消跟踪，应先保留文件并完成相同操作，
再拉取包含云端删除的提交。Git 提交本身不能要求其他克隆把被删除文件自动转成
未跟踪文件。
