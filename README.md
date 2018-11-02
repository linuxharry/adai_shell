# adai_shell
在此记录平时使用到的各类shell脚本。

## 清理仓库中垃圾文件

master直接修改.gitignore文件,将不需要的文件过滤掉，然后执行命令

```bash
git rm -r --cached .
git add .
git commit
git push  -u origin master
```