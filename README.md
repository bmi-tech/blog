# BMI 技术博客

- [BMI 技术博客](#bmi-%e6%8a%80%e6%9c%af%e5%8d%9a%e5%ae%a2)
  - [问题讨论](#%e9%97%ae%e9%a2%98%e8%ae%a8%e8%ae%ba)
  - [博客管理](#%e5%8d%9a%e5%ae%a2%e7%ae%a1%e7%90%86)
    - [本地环境](#%e6%9c%ac%e5%9c%b0%e7%8e%af%e5%a2%83)

## 问题讨论

参阅[项目维基](http://192.168.1.36/ylrc/share/bmi_faqs/wikis/home)。

## 博客管理

- 讨论结束后，涉及到相关技术细节等，根据需求可整理正博客，发布在工程目录，并可根据需要举行小组分享会。
- 使用 Sphinx + ReadTheDocs + Gitlab CI/CD + Apache2 管理博客。
- Sphinx 支持 rst 格式文档，语法类似 Markdown。
- **博客建议使用 reStructuredText 格式**，在相关 issue 之后添加博客链接。
- reStructuredText 学习链接
  - [从 Markdown 到 reStructuredTex](https://macplay.github.io/posts/cong-markdown-dao-restructuredtext/)
  - [reStructuredText入门](http://www.pythondoc.com/sphinx/rest.html)
  - 如果习惯用 Markdown，建议用 [pandoc](https://pandoc.org/try/?text=&from=markdown&to=rst) 一键转化即可

### 本地环境

依赖：基于 Python3 环境构建, 需要使用 Sphinx 库生成, 同时需要安装相应插件

```sh
pip3 install sphinx sphinx-autobuild sphinx_rtd_theme recommonmark pypandoc
```

之后可在项目根目录运行 `make html` (Windows 下运行 `.\make.bat html`) 在本地编译，然后在浏览器打开[文件](build/html/index.html)进行预览。
也可在本地部署 [Apache](https://www.linuxidc.com/Linux/2013-06/85827.htm) 服务，将编译生成的 html 文件拷贝到对应目录查看。

**建议提交前在本地部署和查看效果。**
