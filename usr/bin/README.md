# `/usr/bin` 覆盖目录

把需要覆盖或新增到 `/usr/bin` 的文件、目录或压缩包放到这里。

支持的示例：

```text
files/usr/bin/tool-aarch64.tar.gz
files/usr/bin/tool.zip
files/usr/bin/tool/
```
对于压缩包和目录，scripts/stage-overlay.sh 会解压或扫描其中的内容，并把最匹配的可执行文件安装到固件的 /usr/bin 目录下。

直接放入的文件会原样复制，并自动标记为可执行文件。

README.md 和 .gitkeep 会被 staging 脚本忽略。