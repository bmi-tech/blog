=======
ShowDoc
=======

:作者: mazhuang
:日期: 2020/01/15

关于 ShowDoc
-----------

ShowDoc 概述
~~~~~~~~~~~

一个非常适合IT团队的在线API文档、技术文档工具

ShowDoc 用途
~~~~~~~~~~~

- **API文档**: (`api Demo`_)  

  随着移动互联网的发展，BaaS（后端即服务）越来越流行。服务端提供API，APP端或者网页前端便可方便调用数据。用ShowDoc可以非常方便快速地编写出美观的API文档。

- **数据字典**: (`data Demo`_) 

  一份好的数据字典可以很方便地向别人说明你的数据库结构，如各个字段的释义等。

- **说明文档**: (`doc Demo`_)

  你完全可以使用showdoc来编写一些工具的说明书,也可以编写一些技术规范说明文档以供团队查阅

.. _api Demo: https://www.showdoc.cc/demo?page_id=7
.. _data Demo: https://www.showdoc.cc/data-dictionary?page_id=13
.. _doc Demo: https://www.showdoc.cc/help?page_id=1385767280275683

ShowDoc 功能
~~~~~~~~~~~

- 分享与导出
- 权限管理
- markdown编辑
- 模板插入
- 版本控制
- mock测试(不完善)

ShowDoc 部署
-----------

目前服务部署在97服务器上，访问 http://192.168.1.79:10000

.. code:: sh

    # 拉取镜像，已经传到公司docker仓库
    docker pull dockerhub.bmi:5000/showdoc:latest
    # 新建数据存储路径，并修改权限
    mkdir -p /showdoc_data/html
    chmod -R 777 /showdoc_data
    # 启动showdoc容器
    docker run -d --name showdoc -p 10000:80 -v /showdoc_data/html:/var/www/html/ --restart=always dockerhub.bmi:5000/showdoc:latest

打开 http://localhost:10000 来访问showdoc (localhost可改为你的服务器域名或者IP)。账户密码是showdoc/123456，登录后你便可以看到右上方的管理后台入口。建议登录后修改密码。

ShowDoc 服务迁移
~~~~~~~~~~~~~~

数据放在 ``/showdoc_data/html`` 下。复制旧服务器的 ``Sqlite/showdoc.db.php`` ，以及 ``Public/Uploads/`` 下的所有文件（如没有则可忽略之），覆盖到新showdoc目录的相应文件。覆盖后重新给这些文件可写权限.
