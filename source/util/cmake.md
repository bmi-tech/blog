# CMake

## 概述

### cmake是什么

cmake是一款优秀的工程构建工具。KDE开发者在使用了近10年autotools之后，终于决定为KDE4选择一个新的工程构建工具。

### 特点

- 开放源代码
- 跨平台，在Linux/Unix上，生成makefile；在MacOS上生成xcode；在windows上生成MSVC的工程文件
- 简化编译构建过程和编译过程，工具链简单cmake + make
- 高效，比autotools快%40,主要是因为在工具链中没有libtool
- 可拓展，可以为cmake编写特定功能的模块，扩充cmake功能
- 额外的构建目录树（采用外部构建），不用担心任何删除源码文件的风险
- 支持机器字节序以及其他硬件特性问题的测试
- 在大部分平台下支持并行构建和自动生成文件依赖

### 与autotools、qmake比较

- autotools在windows平台不友好，工具链太长，需要用户操作的地方太多
- qmake是与cmake最相似的，是qt框架内自建的工程构建工具，尽管它缺少一些CMake中提供的一些系统适配的功能

- - -

## 基本语法

### 基本格式

```cmake
command(arg1 arg2 ...)

    #运行命令

set(var_name var_value)

    #定义变量,或者给已经存在的变量赋值，使用变量则是 ${VAR_NAME}。注意：如果是在IF控制语句中，不能使用 ${}，而是直接使用 VAR_NAME

command(arg1 ${var_name})
    #使用变量
```

### 指令参考

```cmake
PROJECT(projectname)
    # 项目名

SET(VAR [VALUE] [CACHE TYPE DOCSTRING [FORCE]])
    # SET定义变量。使用变量则是${VAR_NAME}。注意：如果是在IF控制语句中，不能使用${}，而是直接使用VAR_NAME。

MESSAGE([SEND_ERROR | STATUS | FATAL_ERROR] "message to display"...)
    # MESSAGE向终端输出用户定义的信息，FATAL_ERROR会立即终止cmake编译过程。

ADD_EXECUTABLE(exe ${SRC_LIST})
    # 生成可执行文件 exe

ADD_LIBRARY(mod [SHARED|STATIC|MODULE] ${SRC_LIST})
    # 生成库 动态库 | 静态库 | 模块

ADD_SUBDIRECTORY(source_dir [binary_dir] [EXCLUDE_FROM_ALL])
    # ADD_SUBDIRECTORY指定cmake子目录源代码所在路径，以及编译后二进制文件存放目录。

$ENV{HOME}
    # 使用环境变量 HOME

INCLUDE_DIRECTORIES(header_file_dir)
    # 添加头文件搜索目录

LINK_DIRECTORIES(lib_file_dir)
    # 添加库文件搜索目录

TARGET_LINK_LIBRARIES(exe mod1)
    # 将 libmod1.so 链接到 exe 中

ADD_DEFINITIONS(-DENABLE_DEBUG)
    # 向C/C++编译器中添加宏定义 ENABLE_DEBUG

ADD_DEPENDENCIES(target-name depend-target1 )
    # 定义依赖

AUX_SOURCE_DIRECTORY(. SRC_LIST)
    # AUX_SOURCE_DIRECTORY发现一个目录下所有的源代码文件并将列表存储在一个变量中。

EXEC_PROGRAM(ls ARGS "*.c" OUTPUT_VARIABLE LS_OUTPUT RETURN_VALUE LS_RVALUE)
IF(not LS_RVALUE)
    MESSAGE(STATUS "ls result: " ${LS_OUTPUT})
ENDIF(not LS_RVALUE)
    # EXEC_PROGRAM用于在构建时，运行shell命令，ARGS指明参数，OUTPUT_VARIABLE LS_OUTPUT RETURN_VALUE LS_RVALUE 存储了命令运行的结果。

INCLUDE(file1 [OPTIONAL])
    # 载入 CMakeLists.txt　文件

INCLUDE(module [OPTIONAL])
    # 载入 cmake 模块

OPTIONAL参数的作用是文件不存在也不会产生错误。

```

### 变量参考

```cmake
# 构建发生的目录
CMAKE_BINARY_DIR
PROJECT_BINARY_DIR
<projectname>_BINARY_DIR

# 不论采用何种编译方式，都是工程顶层目录
CMAKE_SOURCE_DIR
PROJECT_SOURCE_DIR
<projectname>_SOURCE_DIR

CMAKE_CURRENT_SOURCE_DIR  # 当前处理的CMakeLists.txt所在的路径

CMAKE_CURRRENT_BINARY_DIR # 内部编译: 跟CMAKE_CURRENT_SOURCE_DIR一致
                          # 外部编译: 指的是构建目录
                          # add_subdirectory(src bin) 会更改它的值为 bin

CMAKE_CURRENT_LIST_FILE   # 当前输出所在的CMakeLists.txt的完整路径
CMAKE_CURRENT_LIST_LINE   # 当前输出所在的行
CMAKE_MODULE_PATH         # 模块所在路径

EXECUTABLE_OUTPUT_PATH    # 可执行文件存放目录
LIBRARY_OUTPUT_PATH       # 库存放目录

CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE # 将工程提供的头文件目录始终置于系统头文件目录的前面

CMAKE_INCLUDE_PATH        # 头文件搜索目录

CMAKE_LIBRARY_PATH        # 库搜索目录
```

### 系统信息

```cmake
CMAKE_MAJOR_VERSION       # CMAKE主版本号，比如2.4.6中的2
CMAKE_MINOR_VERSION       # CMAKE次版本号，比如2.4.6中的4
CMAKE_PATCH_VERSION       # CMAKE补丁等级，比如2.4.6中的6
CMAKE_SYSTEM              # 系统名称，比如Linux-2.6.22
CMAKE_SYSTEM_NAME         # 不包含版本的系统名，比如Linux
CMAKE_SYSTEM_VERSION      # 系统版本，比如2.6.22
CMAKE_SYSTEM_PROCESSOR    # 处理器名称，比如i686
UNIX                      # 在所有的类Unix平台为TRUE，包括OSX和cygwin
WIN32                     # 在所有的Win32平台为TRUE，包括cygwin
```

### 开关选项

```sh
CMAKE_ALLOW_LOOSE_LOOP_CONSTRUCTS   # 用来控制IF ELSE语句的书写方式
BUILD_SHARED_LIBS                   # 这个开关用来控制默认的库编译方式: 动态库 静态库
CMAKE_C_FLAGS                       # 设置C编译选项
MAKE_CXX_FLAGS                      # MAKE_CXX_FLAGS
CMAKE_INCLUDE_CURRENT_DIR           # 自动将每个CMakeLists.txt的所在目录依次加入到 头文件搜索目录
```

### 编译参数相关

```cmake
message(STATUS "CMAKE_C_FLAGS = " ${CMAKE_C_FLAGS})
message(STATUS "CMAKE_C_FLAGS_DEBUG = " ${CMAKE_C_FLAGS_DEBUG})
message(STATUS "CMAKE_C_FLAGS_RELEASE = " ${CMAKE_C_FLAGS_RELEASE})

message(STATUS "CMAKE_CXX_FLAGS = " ${CMAKE_CXX_FLAGS})
message(STATUS "CMAKE_CXX_FLAGS_DEBUG = " ${CMAKE_CXX_FLAGS_DEBUG})
message(STATUS "CMAKE_CXX_FLAGS_RELEASE = " ${CMAKE_CXX_FLAGS_RELEASE})

message(STATUS "CMAKE_EXE_LINKER_FLAGS = " ${CMAKE_EXE_LINKER_FLAGS})
message(STATUS "CMAKE_EXE_LINKER_FLAGS_DEBUG = " ${CMAKE_EXE_LINKER_FLAGS_DEBUG})
message(STATUS "CMAKE_EXE_LINKER_FLAGS_RELEASE = " ${CMAKE_EXE_LINKER_FLAGS_RELEASE})

message(STATUS "CMAKE_SHARED_LINKER_FLAGS = " ${CMAKE_SHARED_LINKER_FLAGS})
message(STATUS "CMAKE_SHARED_LINKER_FLAGS_DEBUG = " ${CMAKE_SHARED_LINKER_FLAGS_DEBUG})
message(STATUS "CMAKE_SHARED_LINKER_FLAGS_RELEASE = " ${CMAKE_SHARED_LINKER_FLAGS_RELEASE})

message(STATUS "CMAKE_STATIC_LINKER_FLAGS = " ${CMAKE_STATIC_LINKER_FLAGS})
message(STATUS "CMAKE_STATIC_LINKER_FLAGS_DEBUG = " ${CMAKE_STATIC_LINKER_FLAGS_DEBUG})
message(STATUS "CMAKE_STATIC_LINKER_FLAGS_RELEASE = " ${CMAKE_STATIC_LINKER_FLAGS_RELEASE})
```

### 安装INSTLL

```cmake
INSTALL(TARGETS targets...
        [[ARCHIVE|LIBRARY|RUNTIME]
                   [DESTINATION <dir>]
                   [PERMISSIONS permissions...]
                   [CONFIGURATIONS
        [Debug|Release|...]]
                   [COMPONENT <component>]
                   [OPTIONAL]
                ] [...])
```

说明

- 参数中的`TARGETS`后面跟的就是我们通过ADD_EXECUTABLE或者ADD_LIBRARY定义的目标文件，可能是可执行二进制、动态库、静态库。

- 目标类型也就相对应的有三种，`ARCHIVE`特指静态库，`LIBRARY`特指动态库，`RUNTIME`特指可执行目标二进制。
- `DESTINATION`定义了安装的路径，如果路径以/开头，那么指的是绝对路径，这时候`CMAKE_INSTALL_PREFIX`其实就无效了。如果你希望使用`CMAKE_INSTALL_PREFIX`来定义安装路径，就要写成相对路径，即不要以/开头，那么安装后的路径就是`${CMAKE_INSTALL_PREFIX}/[DESTINATION定义的路径]`

```cmake
 INSTALL(TARGETS myrun mylib mystaticlib
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION libstatic
 )

 可执行二进制myrun安装到${CMAKE_INSTALL_PREFIX}/bin目录
 动态库libmylib安装到${CMAKE_INSTALL_PREFIX}/lib目录
 静态库libmystaticlib安装到${CMAKE_INSTALL_PREFIX}/libstatic目录
 特别注意的是你不需要关心TARGETS具体生成的路径，只需要写上TARGETS名称就可以
```

### 控制语句

```cmake
IF(expression)
    COMMAND1(ARGS)
ELSE(expression)
    COMMAND2(ARGS)
ENDIF(expression)
```

### 表达式

```cmake
IF(var)                       # 不是空, 0, N, NO, OFF, FALSE, NOTFOUND 或 <var>_NOTFOUND时，为真
IF(NOT var)                   # 与上述条件相反。
IF(var1 AND var2)             # 当两个变量都为真是为真。
IF(var1 OR var2)              # 当两个变量其中一个为真时为真。
IF(COMMAND cmd)               # 当给定的cmd确实是命令并可以调用是为真
IF(EXISTS dir)                # 目录名存在
IF(EXISTS file)               # 文件名存在
IF(IS_DIRECTORY dirname)      # 当dirname是目录
IF(file1 IS_NEWER_THAN file2) # 当file1比file2新,为真
IF(variable MATCHES regex)    # 符合正则
```

### 循环

```cmake
WHILE(condition)
    COMMAND1(ARGS)
    // ...
ENDWHILE(condition)
```

```cmake
AUX_SOURCE_DIRECTORY(. SRC_LIST)
FOREACH(one_dir ${SRC_LIST})
    MESSAGE(${one_dir})
ENDFOREACH(onedir)
```

- - -

## 构建

### 内部构建

1. 在cmake-demo目录下执行 `cmake .`
2. 就可以看到cmake为项目生产的Makefile文件，以及一些cmake缓存文件,执行命令`make`

### 外部构建

内部构建生成的Cmake的中间文件与源代码文件混杂在一起，并且cmake没有提供清理这些中间文件的命令,所以cmake推荐使用外部构建，步骤如下:

1. 在CMakeLists.txt的同级目录下，新建一个build文件夹
2. 进入build文件夹，执行`cmake ..`命令，这样所有的中间文件以及Makefile都在build目录下了
3. 在build目录下执行`make`就可以得到可执行文件

## 项目测试

测试地址`git@gitlab.bmi:lijinwen/cmake.git`

- hello 内部构建和外部构建 案例
- demo1 将mod1模块作为动态库 案例
- demo2 mod1依赖静态库mod2 案例
- demo3 make install 案例

- - -

## 作者

- 李锦文
- 2019/11/13 16:08

## 声明

本文档为BMI内部文档，仓促之作，难免有误，请勿直接修改git版本，请先联系作者，交于作者更正补充，请多多指教。
