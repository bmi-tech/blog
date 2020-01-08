# BMI C++ 代码风格指南

```text
作者: kiki
日期: 2020/1/4
```

## 0 扉页

节选抄录自`Google开源项目风格指南(中文版)-C++风格指南`。
>原文 :[https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/](https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/)

除以下章节外, 其余章节皆与原文一致:

- [5 其他C++特性](#5-%e5%85%b6%e4%bb%96-c-%e7%89%b9%e6%80%a7)
- [6 命名约定](#6-%e5%91%bd%e5%90%8d%e7%ba%a6%e5%ae%9a)
- [7 注释](#7-%e6%b3%a8%e9%87%8a)
- [8 格式](#8-%e6%a0%bc%e5%bc%8f)

如果在阅读本文其他章节的过程中遇到困惑，可跳转至 GoogleC++ 原文进行阅读。

## 1 头文件

### 1.1 #define 保护

所有头文件都应该使用 `#define` 来防止头文件被多重包含, 命名格式当是: `<PROJECT>_<PATH>_<FILE>_H_`.

为保证唯一性, 头文件的命名应该基于所在项目源代码树的全路径. 例如, 项目 foo 中的头文件 `foo/src/bar/baz.h` 可按如下方式保护:

```c++
#ifndef FOO_BAR_BAZ_H_
#define FOO_BAR_BAZ_H_
...
#endif // FOO_BAR_BAZ_H_
```

注意:

- QTCreator 默认创建的文件宏名为 `<FILE>_H`, 没有包含全路径，所以同一项目内避免出现文件名相同的文件。

### 1.2 include 的路径及顺序

项目内头文件应按照项目源代码目录树结构排列

```c++
//优先位置， cpp/cc中优先包含
#include "a.h"
//系统文件
#include <sys/types.h>
#include <sys/socket.h>
//系统库
#include <unordered_map>
//第三方库
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>
//项目内自定义头文件
#include "cnetwork.h"
#include "cdatetime.h"
#include "cstring.h"
```

注意:

- 避免使用相对路径的包含, eg: **#incldue<../../cmp.h>**

## 2 作用域

### 2.1 命名空间

```txt
命名空间将全局作用域细分为独立的, 具名的作用域, 可有效防止全局作用域的命名冲突.
```

合理运用命名空间:

- 禁止使用内联命名空间 **（inline namespace）**
- 遵守[命名空间命名规则](#namespace-names)
- 命名空间的最后注释出命名空间的名字
- 将所有声明与定义都置于命名空间中， 不要使用缩进
- 不要在命名空间 `std` 中声明任何东西，包括标准库的类前置声明，在 `std` 命名空间声明实体是未定义的行为, 会导致如不可移植. 声明标准库下的实体, 需要包含对应的头文件.
- 禁止在头文件中使用 `using namespace xxx`
- 不要在头文件中使用命名空间别名 `namespace baz = ::foo::bar::baz`, 除非标明内部使用，因为任何在头文件中引入的命名空间都会成为公开 API 的一部分。
- 命名空间内的函数实现时，需要包含在命名空间中或者使用作用域符号限定。

代码示例:

```c++
//.h文件
//using namespace std; 禁止在头文件中使用`using namespace xxx`
namespace cdatetime{ //名称全小写
namespace logutil = bmilog::logutil;//仅限内部使用

bool GetCurrentDateTime(std::string &strtime, std::string strformat); //不要使用缩进

}//namespace cdatetim 最后释放命名空间名字


//.cpp文件
namespace cdatetime{
bool GetCurrentDateTime(std::string &strtime, std::string strformat)
{
    return true;
}
}//namespace cdatetim

//.cpp文件
//或者使用以下方法进行定义
bool cdatetime::GetCurrentDateTime(std::string &strtime, std::string strformat)
{
    return true;
}

//禁止使用以下方式进行定义, 以下方式会导致链接时失败，找不到符号
//.cpp文件
using namespace cdatetime;
bool GetCurrentDateTime(std::string &strtime, std::string strformat)
{
    return true;
}
```

### 2.2 匿名命名空间和静态变量

- `当一个不需要被外部引用的变量被定义时，可以在源文件中将他们放到匿名命名空间或者声明为static。`
- 所有置于匿名命名空间的声明都具有内部链接性，函数和变量可以经由声明为 `static` 拥有内部链接性，这意味着你在这个文件中声明的这些标识符都不能在另一个文件中被访问。即使两个文件声明了完全一样名字的标识符，它们所指向的实体实际上是完全不同的。

推荐、鼓励在 `.cc` 中对于不需要在其他地方引用的标识符使用内部链接性声明，但是不要在 `.h` 中使用。
匿名命名空间的声明和具名的格式相同，在最后注释上 `namespace`:

```c++
namespace {
...
}  // namespace
```

### 2.3 非成员函数、静态成员函数和全局函数

合理运用：

- 使用静态成员函数或命名空间内的非成员函数, 尽量不要用裸的全局函数.
- 将一系列函数直接置于命名空间中，不要用类的静态方法模拟出命名空间的效果，类的静态方法应当和类的实例或静态数据紧密相关.

有时, 把函数的定义同类的实例脱钩是有益的, 甚至是必要的. 这样的函数可以被定义成静态成员, 或是非成员函数.
非成员函数不应依赖于外部变量, 应尽量置于某个命名空间内. 相比单纯为了封装若干不共享任何静态数据的静态成员函数而创建类, 不如使用命名空间 。
举例而言，对于头文件 `myproject/foo_bar.h`, 应当使用

```c++
namespace myproject {
namespace foo_bar {
void Function1();
void Function2();
}  // namespace foo_bar
}  // namespace myproject

//而非
namespace myproject {
class FooBar
{
public:
    static void Function1();
    static void Function2();
};
}  // namespace myproject
```

### 2.4 局部变量

- `将函数变量尽可能置于最小作用域内, 并在变量声明时进行初始化`

C++ 允许在函数的任何位置声明变量. 我们提倡在尽可能小的作用域中声明变量, 离第一次使用越近越好. 这使得代码浏览者更容易定位变量声明的位置, 了解变量的类型和初始值. 特别是，应使用初始化的方式替代声明再赋值, 比如:

```c++
int i;
i = f(); // 坏——初始化和声明分离

int j = g(); // 好——初始化时声明

vector<int> v;
v.push_back(1); // 用花括号初始化更好
v.push_back(2);

vector<int> v = {1, 2}; // 好——v 一开始就初始化
```

属于 if, while 和 for 语句的变量应当在这些语句中正常地声明，这样子这些变量的作用域就被限制在这些语句中了，举例而言:

```c++
while (const char* p = strchr(str, '/'))
    str = p + 1;
```

**警告**: 如果变量是一个对象, 每次进入作用域都要调用其构造函数, 每次退出作用域都要调用其析构函数. 这会导致效率降低.

```c++
// 低效的实现
for (int i = 0; i < 1000000; ++i)
{
    Foo f;                  // 构造函数和析构函数分别调用 1000000 次!
    f.DoSomething(i);
}

//正常的实现
Foo f;                      // 构造函数和析构函数只调用 1 次
for (int i = 0; i < 1000000; ++i)
{
    f.DoSomething(i);
}
```

### 2.5 静态和全局变量

- `禁止定义静态储存周期非POD变量`：

  静态生存周期的对象，即包括了`全局变量`，`静态变量`，静态类成员变量和函数静态变量，都必须是原生数据类型 (POD : PlainOld Data): 即 int, char 和 float, 以及 POD 类型的指针、数组和结构体。

  由于构造和析构函数调用顺序的不确定性，它们会导致难以发现的 bug。`constexpr` 变量除外，它不涉及动态初始化或析构。
  
  静态变量的构造函数、析构函数、以及初始化顺序在一个编译单元内是明确的，静态初始化优先于动态初始化，初始化顺序按照明顺序进行，销毁则逆序。但是在`不同的编译单元`之间初始化和销毁顺序都属于`未明确行为`（unspecified behaviour）。
  
  函数作用域里的静态变量除外，毕竟它的初始化顺序是有明确定义的，而且只会在指令执行到它的声明那里才会发生。

- `禁止使用含有副作用的函数初始化POD全局变量`:

  涉及到全局变量的函数是被认为是有副作用的。`getpid()`， `getenv()` 等不涉及到全局变量的函数可用来初始化 POD 全局变量。

错误代码示例:

```c++
//BMILogUtil.h
#include "LogConfig.h"
using BMILogger = std::shared_ptr<spdlog::logger>;
class BMILogUtil
{
    static BMILogger    m_ConsoleLogger;
    static LogConfig    m_Global_Config;
};

//LogConfig.h
class LogConfig
{
public:
    LogConfig();
    ...
};

//BMILogUtil.cpp
#include "BMILogUtil.h"
#include <spdlog/spdlog.h>
using namespace std;
BMILogger BMILogUtil::m_ConsoleLogger = spdlog::stdout_logger_mt("Default_Console_Logger");
LogConfig BMILogUtil::m_Global_Config;


//.pro文件
//会导致崩溃
SOURCES += \
    BMILogUtil.cpp \
    LogConfig.cpp \

//.pro文件
//修正后正确运行
SOURCES += \
    LogConfig.cpp \
    BMILogUtil.cpp
```

综上所述，我们只允许 POD 类型的静态变量，即完全禁用 `vector` (使用 C 数组替代) 和 `string` (使用 `const char []`)

- 如果您确实需要一个 class 类型的静态或全局变量，可以考虑在 main() 函数内初始化一个指针且永不回收.
- 注意只能用 raw 指针,别用智能指针，后者的析构函数涉及到上文指出的不定顺序问题。

## 3 类

类是 C++ 中代码的基本单元. 显然, 它们被广泛使用. 本节列举了在写一个类时的主要注意事项.

### 3.1 构造函数

- `不要在构造函数中调用虚函数`

  如果在构造函数内调用了自身的虚函数, 这类调用是不会重定向到子类的虚函数实现. 即使当前没有子类化实现, 将来仍是隐患.

- `不要在无法报出错误时进行可能失败的初始化`

  在没有使程序崩溃或者使用异常(注意, 被禁用)等方法的条件下, 构造函数很难上报错误。 例如，传入参数为一个 url, 如果 url 不合法，构造函数也无法上报错误。

  如果执行失败, 会得到一个初始化失败的对象, 这个对象有可能进入不正常的状态, 必须使用 `bool IsValid()` 或类似这样的机制才能检查出来, 然而这是一个十分容易被疏忽的方法.

**结论:**

- 构造函数不允许调用虚函数. 如果代码允许, 直接终止程序是一个合适的处理错误的方式. 否则, 考虑用 `Init()` 方法或工厂函数.
- 构造函数不得调用虚函数, 或尝试报告一个非致命错误. 如果对象需要进行有意义的 (non-trivial) 初始化, 考虑使用明确的 `Init()` 方法或使用工厂模式.

### 3.2 隐式类型转换

- 不要定义隐式类型转换. 对于`转换运算符`和`单参数`构造函数, 请使用 `explicit` 关键字.

隐式类型转换允许一个某种类型 (称作 `源类型`) 的对象被用于需要另一种类型 (称作 `目的类型`) 的位置.
例如, 将一个 `int` 类型的参数传递给需要 `double` 类型的函数.

除了语言所定义的隐式类型转换, 用户还可以通过在类定义中添加合适的成员定义自己需要的转换.
在`源类型`中定义隐式类型转换, 可以通过`目的类型名`的`类型转换运算符`实现(例如 `operator bool()`).
在目的类型中定义隐式类型转换, 则通过以源类型作为其唯一参数 (或唯一无默认值的参数) 的构造函数实现.

**代码示例:**

不加 `explicit` 的限定:

```c++
#include <iostream>
class MyClass
{
public:
    MyClass(int data)
    {
        m_data = data;
    }
    operator std::string(){
        return std::to_string(m_data);
    }
    int GetData(){ return m_data; }
private:
    int m_data;
};
int main()
{
    MyClass myClass = 'a'; //转换有风险
    std::cout << myClass.GetData() << std::endl;
    std::string myStr = myClass; //转换有风险
    std::cout << myStr << std::endl;
    return 0;
}
```

添加 `explicit` 的限定:

```c++
#include <iostream>
class MyClass
{
public:
    explicit MyClass(int data)
    {
        m_data = data;
    }
    explicit operator std::string(){
        return std::to_string(m_data);
    }
    int GetData(){ return m_data; }
private:
    int m_data;
};
int main()
{
//  MyClass myClass = 'a';    错,无法通过编译
//  std::string str = myClass;错,无法通过编译
    MyClass myClass('a');//转换无风险，已明确:字符'a'作为参数转化为int构造MyClass
    std::cout << myClass.GetData() << std::endl;
    std::cout << std::string(myClass) << std::endl;
    return 0;
}
```

**注意:**

- `拷贝构造函数`和`移动构造函数`不应当被标记为 `explicit`, 因为它们并不执行类型转换.
- 参数个数不为1的构造函数不应当加上 `explicit`.
- 接受一个`std::initializer_list` 作为参数的构造函数也应当省略 `explicit`, 以便支持拷贝初始化 (例如 `MyType m = {1, 2};`)

### 3.3 可拷贝类型和可移动类型

规定:

- `如果你的类型定义了拷贝/移动操作, 则要保证这些操作的默认实现是正确的`
- `给出拷贝/移动构造的同时，也应该给出相应的赋值操作`

  记得时刻检查默认操作的正确性, 并且在文档中说明类是可拷贝的且/或可移动的.

  ```c++
  class Foo
  {
  public:
      Foo(Foo&& other) : m_fileid(other.field) {}
      // 差, 只定义了移动构造函数, 而没有定义对应的赋值运算符.
  private:
      Field m_fileid;
  };
  ```

- `由于存在对象切割的风险, 不要为在基类中提供赋值操作或者拷贝/移动构造函数`

  不要有继承这样的成员函数的类,如果你的基类需要可复制属性, 请提供一个 `public virtual Clone()` 和一个 `protected` 的拷贝构造函数以供派生类实现.

  ```c++
  Class MyClass
  {
  public:
      vitrual MyClass * Clone()
      {
          MyClass * myclass;
          ...
          return myclass;
      }
  protected:
      MyClass(MyClass & myclass)
      {
      }
  };
  ```

- `如果你的类型不需要拷贝/移动就把他们禁用。`

  ```c++
  MyClass(const MyClass&) = delete;
  MyClass& operator=(const MyClass&) = delete;
  //也可通过宏来禁用
  #define DISALLOW_COPY_AND_ASSIGN(TypeName) \
      TypeName(const TypeName &) = delete; \
      TypeName& operator = (const TypeName &) = delete
  ```

> google 开源项目指南 3.3 原文:[https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/classes/#copyable-and-movable-types](https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/classes/#copyable-and-movable-types)

### 3.4 结构体 VS 类

- `仅当只有数据成员时使用 struct, 其它一概使用 class.`

在 C++ 中 `struct` 和 `class` 关键字几乎含义一样. 我们为这两个关键字添加我们自己的语义理解, 以便为定义的数据类型选择合适的关键字.

`struct` 用来定义包含数据的被动式对象, 也可以包含相关的常量, 但除了存取数据成员之外, 没有别的函数功能. 并且存取功能是通过直接访问位域, 而非函数调用.
除了`构造函数`, `析构函数`, `Initialize()`, `Reset()`, `Validate()` 等类似的用于设定数据成员的函数外, 不能提供其它功能的函数.

如果需要更多的函数功能, `class` 更适合. 如果拿不准, 就用 `class`

为了和 STL 保持一致, 对于`仿函数`等特性可以不用 `class` 而是使用 `struct`.

注意:

```txt
类和结构体的成员变量使用不同的命名规则.
```

### 3.5 继承

- `使用组合常常比使用继承更合理`
- `所有继承必须为 Public 的, 如果你想使用私有继承, 你应该替换成把基类的实例作为成员对象的方式.`
- `必要的话，析构函数应该声明为 virtual. 如果你的类有虚函数, 则析构函数也应该为虚函数.`

  一般来说，如果使用者可以保证派生类不会使用多态，即基类只作为接口类实现，那么不使用虚析构函数也是可以的。

  如果不能保证，那么基类必须声明析构函数为 Virtual。

  当然，如果基类中已经有了其他虚函数，那么析构函数一律声明为 Virtual, 无需考虑多态的使用。

- `对于可能被子类访问的成员函数, 不要过度使用 protected 关键字. 注意, 数据成员都必须是 私有的.`

不要过度使用继承. 组合常常更合适一些. 尽量做到只在 “`is-a`”, (其他 “`has-a`” 情况下请使用组合) 的情况下使用继承.

标记为 `override` 或 `final` 的析构函数如果不是对基类虚函数的重载的话, 编译会报错, 这有助于捕获常见的错误。

这些标记起到了文档的作用, 因为如果省略这些关键字, 代码阅读者不得不检查所有父类, 以判断该函数是否是虚函数。

### 3.6 多重继承

真正需要用到多重实现继承的情况少之又少. 只在以下情况我们才允许多重继承:

- 最多只有一个基类是`非抽象类`, 其它基类都是以 `Interface` 为后缀的**纯接口类**.

只有当所有父类除第一个外都是 `纯接口类` 时, 才允许使用多重继承. 为确保它们是纯接口, 这些类必须以 `Interface` 为后缀.

### 3.7 接口

接口是指满足特定条件的类, 这些类以 `Interface` 为后缀 (不强制).

当一个类满足以下要求时, 称之为纯接口:

- 只有纯虚函数 (“=0”) 和静态函数 (除了下文提到的析构函数).
- 没有非静态数据成员.
- 没有定义任何构造函数. 如果有, 也不能带有参数, 并且必须为 protected.
- 如果它是一个子类, 也只能从满足上述条件并以 Interface 为后缀的类继承.

接口类不能被直接实例化, 因为它声明了纯虚函数. 为确保接口类的所有实现可被正确销毁, 必须为之声明虚析构函数 (作为上述第 1 条规则的特例, 析构函数不能是纯虚函数).

### 3.8 运算符重载

- 除少数特定环境外, 不要重载运算符. 也不要创建用户定义字面量.

> google 规范原文:[https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/classes/#id10](https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/classes/#id10)

### 3.9 存取控制

将所有数据成员声明为 `private`, 除非是 `static const` 类型成员 (遵循常量命名规则).

### 3.10 声明顺序

类定义一般应以 `public:` 开始, 后跟 `protected:`, 最后是 `private:` 省略空部分.
建议以如下顺序声明:

- 类型: 包括 typedef, using, 嵌套的结构体和类
- 常量
- 工厂函数
- 构造函数
- 赋值运算符
- 析构函数
- 其他函数
- 数据成员

### 3.11 总结

1. 在构造函数中做太多逻辑相关的初始化;
2. 编译器提供的默认构造函数不会对变量进行初始化, 如果定义了其他构造函数, 编译器不再提供, 需要编码者自行提供默认构造函数;
3. 为避免隐式转换, 需将单参数构造函数声明为 `explicit`;
4. 为避免`拷贝构造函数`, `赋值操作`的滥用和编译器自动生成, 可将其声明为 private 且无需实现;
5. 仅在作为数据集合时使用 struct;
6. `组合` > `实现继承` > `接口继承` > `私有继承`, 子类重载的虚函数也要声明 `virtual` 关键字, 虽然编译器允许不这样做;
7. 避免使用多重继承, 使用时, 除一个基类含有实现外, 其他基类均为纯接口;
8. 接口类类名以 `Interface` 为后缀, 除提供带实现的虚析构函数, 静态成员函数外, 其他均为纯虚函数, 不定义非静态数据成员, 不提供构造函数, 提供的话, 声明为 protected;
9. 为降低复杂性, 尽量不重载操作符, 模板, 标准类中使用时提供文档说明;
10. 存取函数一般`内联`在头文件中;
11. 声明次序: `public` -> `protected` -> `private`;
12. 函数体尽量短小, 紧凑, 功能单一;

## 4 函数

### 4.1 参数顺序

```txt
函数的参数顺序为: 输入参数在先, 后跟输出参数.
特别要注意, 在加入新参数时不要因为它们是新参数就置于参数列表最后, 而是仍然要按照前述的规则, 即将新的输入参数也置于输出参数之前.
```

### 4.2 编写简短函数

```txt
我们倾向于编写简短, 凝练的函数.
```

我们承认长函数有时是合理的, 因此并不硬性限制函数的长度. 如果函数超过 `40` 行, 可以思索一下能不能在不影响程序结构的前提下对其进行分割.

即使一个长函数现在工作的非常好, 一旦有人对其修改, 有可能出现新的问题, 甚至导致难以发现的 bug. 使函数尽量简短, 以便于他人阅读和修改代码.

在处理代码时, 你可能会发现复杂的长函数. 不要害怕修改现有代码: 如果证实这些代码使用 / 调试起来很困难, 或者你只需要使用其中的一小段代码, 考虑将其分割为更加简短并易于管理的若干函数.

### 4.3 引用参数

- 所有按引用传递的参数必须加上 `const`.
- 输入参数是`值参`或 `const 引用`, 输出参数为`指针`.
  
  ```c++
  void Foo(const string &in, string *out);
  ```

有时候, 在输入形参中用 `const T*` 指针比 `const T&` 更明智. 比如:

- 可能会传递空指针.
- 函数要把指针或对地址的引用赋值给输入形参.

总而言之, 大多时候输入形参往往是 `const T&`. 若用 `const T*` 则说明输入另有处理. 所以若要使用 `const T*`, 则应给出相应的理由, 否则会使得读者感到迷惑.

> [const T、const T*、T *const、const T&、const T*& 的区别](https://www.cnblogs.com/lzpong/p/6479383.html)

### 4.4 函数重载

- 不要单靠`不同的参数类型`来重载，这意味着参数的个数不变。
- 当需要重载的函数参数类型改变时，不妨试着改变函数名称
- 如果重载函数的目的是为了支持`不同数量的同一类型参数`, 则优先考虑使用 `std::vector` 以便使用者可以用 `列表初始化` 指定参数.

```c++
class MyString
{
    public:
    void Append(const string &text);
    void Append(const char *text, size_t textlen);
    void Append(int number);//不好
    void AppendInt(int number;)//好
    //不同数量的同一参数。或者采用:void AppendMutilString(std::vector<string> strVector);
    void Append(std::vector<string> strVector);
};
```

### 4.5 缺省参数

- 只允许在非虚函数中使用缺省参数, 且必须保证缺省参数的值始终一致。
  - 若有必要在虚函数中使用缺省函数，不要重定义虚函数中的默认参数。

  虚函数调用的缺省参数取决于目标对象的`静态类型`（对象在声明时采用的类型。是在编译期确定的）, 此时无法保证给定函数的所有派生类中重写的声明都是同样的缺省参数.

  也就是说, 虚函数被调用时具体执行派生类的定义还是基类的定义是由运行时决定的(`动态类型`)，而传递的缺省参数则是由编译时决定的（`静态类型`）.

  虚函数使用缺省参数示例:

  ```c++
  #include <iostream>
  using namespace std;
  class Myclass
  {
  public:
      Myclass(){}
      virtual~Myclass(){}
      virtual void Show(int a = 1)
      {
          std::cout << a << std::endl;
      }
  };


  class ClassA: public Myclass
  {
  public:
      virtual void Show(int a = 2)
      {
          std::cout << a << std::endl;
      }
  };

  int main()
  {
      Myclass *   pMyclass = new ClassA;
      ClassA *    pClassA = new ClassA;
      pMyclass->Show(); //输出1
      pClassA->Show();  //输出2
      delete pMyclass;
      delete pClassA;
  }
  ```

- `如果在每个调用点缺省参数的值都有可能不同, 在这种情况下缺省函数也不允许使用.`

  缺省函数调用点重新求值示例:

  ```c++
  #include <iostream>
  using namespace std;
  class Myclass
  {
  public:
      Myclass(int val)
      {
          m_nVal = val;
          s_nEntityTotal++;
      }
      void Show(int val = s_nEntityTotal) //不好，val应该等于常量
      {
          std::cout << val << std::endl;
      }
  private:
      int m_nVal;
      static int s_nEntityTotal;
  };
  int Myclass::s_nEntityTotal = 0;
  int main()
  {
      Myclass a(1);
      a.Show();
      Myclass b(1);
      a.Show();//显示结果不同。
  }
  ```

- `缺省参数`与`函数重载`遵循同样的规则. 一般情况下建议使用`函数重载`

  缺省参数会干扰函数指针, 导致函数签名与调用点的签名不一致. 而函数重载不会导致这样的问题.

  ```c++
  #include <iostream>
  using namespace std;

  typedef void(*fun)(int a);

  void Test(int a = 5)
  {
      std::cout << a << std::endl;
  }

  int main()
  {
      fun f = Test;
      //f();无法通过编译
      f(6);
      return 0;
  }
  ```

### 4.6 函数返回类型后置语法

C++ 现在允许两种不同的函数声明方式. 以往的写法是将返回类型置于函数名之前. 例如:

```c++
int foo(int x);
```

C++11 引入了这一新的形式. 现在可以在函数名前使用 `auto` 关键字, 在参数列表之后后置返回类型. 例如:

```c++
auto foo(int x) -> int;
```

后置返回类型为函数作用域. 对于像 `int` 这样简单的类型, 两种写法没有区别. 但对于复杂的情况, 例如类域中的类型声明或者以函数参数的形式书写的类型, 写法的不同会造成区别.

约定:

- `只有在常规写法不便于书写或不利于阅读的使用返回类型后置语法`

例如:

```c++
#include <vector>
#include <algorithm>

template <class T, class U>
auto add(T t, U u) -> decltype(t + u);

template <class T, class U>
decltype(declval<T&>() + declval<U&>()) add1(T t, U u);


int main()
{
    std::vector<int> vec = {5, 6, 4, 7, 8};
    std::sort(vec.begin(), vec.end(), [](int a, int b) -> bool {
        return a < b;
    });
    return 0;
}
```

## 5 其他 C++ 特性

- 所有引用对象传参都要加上 Const: (`Const T &`)
- C++ 异常可以 `Catch`, 但不能 `throw`
- lambda 的每个捕获对象要都写出来, 如果捕获多个成员变量, 允许捕获 `this`
- 对于迭代器和其他模板对象使用前缀形式 `(++i)` 的自增, 自减运算符
- 用 `sizeof(varname)` 代替 `sizeof(type)`
- 函数中输入参数用`const T &`, 输出参数用指针 `string * str`

## 6 命名约定

最重要的一致性规则是命名管理. 命名的风格能让我们在不需要去查找类型声明的条件下快速地了解某个名字代表的含义: 类型, 变量, 函数, 常量, 宏, 等等, 甚至. 我们大脑中的模式匹配引擎非常依赖这些命名规则.

命名规则具有一定随意性, 但相比按个人喜好命名, 一致性更重要, 所以无论你认为它们是否重要, 规则总归是规则.

### 6.1 通用命名规则

通用规定:

- `函数命名, 变量命名, 文件命名要有描述性; 少用缩写`.

尽可能使用描述性的命名, 别心疼空间, 毕竟相比之下让代码易于新读者理解更重要. 不要用只有项目开发者能理解的缩写, 也不要通过砍掉几个字母来缩写单词.

```c++
uint16_t m_uHttpListenePort;//好，无缩写，一目了然
uint16_t m_uHLP;//坏， 根本无法识别
```

先来介绍两种编程的命名规范:

#### 6.1.1 驼峰命名法

也称骆驼式命名法正如它的名称所表示的那样，是指混合使用大小写字母来构成变量和函数的名字。

根据首字母的大小写又分为大驼峰式命名规则（也叫`帕斯卡`命名规则），与小驼峰式命名规则

```c++
void GetFileName(); //大驼峰式
void getFileName(); //小驼峰式
```

- `我们约定在定义类型与函数时使用驼峰命名法, 类型与公有函数使用大驼峰, 非公有函数使用小驼峰`

#### 6.1.2 匈牙利命名法

匈牙利命名法通过在变量名前面加上相应的小写字母的符号标识作为前缀，标识出变量的作用域，类型等这些符号可以多个同时使用。

- `变量名 = 属性 + 类型 + 描述`

这里属性与类型只选取我们约定使用的，原规定中还有很多复杂的类型。
> [匈牙利命名法-百度百科](https://baike.baidu.com/item/%E5%8C%88%E7%89%99%E5%88%A9%E5%91%BD%E5%90%8D%E6%B3%95/7632397?fr=aladdin)

约定:

- 在声明变量与定义变量时使用匈牙利命名法, `局部变量与结构体成员可省略属性(作用域)`, `类型描述可根据喜好添加`,这里非强制要求, 如果需要添加类型, 需要按照下述描述添加。

属性一般是 `小写字母 + _`:

|属性|解释|
|----|---|
|g_|全局变量|
|m_|类成员变量|
|s_|静态变量|
|c_|常量|

类型比较多，这里只挑选我们约定可选用的几个

|前缀|类型|
|----|----|
|a   |数组 (Array) |
|b   |布尔值 (Boolean)|  
|fn  |函数  |
|f   |浮点型 |
|d   |double，双精度浮点型|
|u   |无符号整形, 无符号长整型，无符号短整形|
|n   |整形、长整型，短整形 (int, long int, short int)|
|p   |Pointer |
|sz  |字符串型|

例如:

```c++
std::string     m_szSessionId;
Session         *m_pSession;
std::string     *m_pszSessionId;//指向字符串的指针
```

### 6.2 文件命名

- 文件名全小写, 不允许使用 `_` 分割。如 `clientsocket.cpp`
- 源文件以 `.cpp/cc` 结尾, 头文件用 `.h`, 专门插入文本的文件以 `.inc` 结尾
- 不要使用存在于 `/usr/include` 下的文件名(即编译器搜索系统头文件的路径),如 `db.h`
- 尽量让文件名更加明确, 少用缩写. 例如 `httpserverlog.h` 比 `logs.h` 好
- 内联函数必须放到 `.h` 中

### 6.3 类型命名

- 类型命名使用`大驼峰式`命名规则, 包括但不限于以下类型

```c++
class MyClass;
struct MyStruct;
enum MyEnum;
typedef MyClass MyClassDef;
using MyClassDef = MyClass;
union MyUnion;
//......
```

### 6.4 变量命名

变量(包括函数参数)和数据成员名, 首字母一律小写, 以`匈牙利命名法`命名

#### 普通变量命名

- 以`匈牙利命名法`命名, `变量 = 类型（不强制要求） + 描述`。

```c++
std::string             szTableName;
struct Picture;
std::vector<Picture *>  vecPicture;
for(int i = 0; i < 100; ++i)
{
    int val = array[i]; //i, temp简单局部变量可以不遵守此命名法，因为一目了然
    Session * pSession = array[i]; //遵守规则更好
}
```

#### 类数据成员

- 以`匈牙利命名法`命名, `变量 = 作用域 + 类型（不强制要求） + 描述`。

```c++
class MyClass
{
private:
    std::string             m_szTableName;
    Session                 *m_pSession;
    std::mutex              m_mutexForListPicturePtr; //描述如果写不清楚再注释中写明意图。
    std::list<Picture*>     m_listPicturePtr;//复杂类型
    Picture                 m_picture; //讨论

    static uint32_t         s_uTotalEntites;//总实例数量
};
```

#### 结构体成员命名

- 以`匈牙利命名法`命名, `变量 = 类型（不强制要求） + 描述`。

```c++
struct Picture
{
    uint8_t     *pData;
    unsigned    uLen;
};
```

#### 全局变量命名

- 以`匈牙利命名法`命名, `变量 = 作用域 + 类型（不强制要求） + 描述`。

```c++
//跨文件引用全局变量(extern), .h中声明
namespace global
{
extern int g_nGlobalVal; //声明全局变量
}//namespace global

//静态全局变量 cpp中声明
static int s_nGlobalVal = 0;
```

### 6.5 常量命名

- 以`匈牙利命名法`命名, `变量 = 作用域 + 类型（不强制要求） + 描述`。

```c++
//普通的常量
const char * c_pModuleName = "CsMysqlModule";
//类中的
class MyClass
{
private:
    static const char * c_pClassName;
};
const char * MyClass::c_pClassName = "MyClass";
//结构体中的
struct MyStruct
{
    static const char * c_pClassName = "MyStruct";
};
```

### 6.6 函数命名

- `Public 函数命名以大驼峰法命名`: 即首字母大写，每个单词开头的首字母大写。
- `Private 与 Protocted 函数命名以小驼峰法命名`: 即首字母小写，每个单词开头的首字母大写。
- 类成员函数，普通函数规定相同

```c++
void Update();
void Notify();
int  GetStatus();
void SetStatus(int status);
class MyClass
{
public:
    int  GetStatus();
private:
    void callLock();
};
```

### 6.7 命名空间命名

- 命名空间名称全小写。
- 不用与常见的命名空间重名,例如 `std`, `boost`

```c++
namespace bmi
{

}//namespace bmi
```

### 6.8 枚举命名

- 枚举命名采用 google 规范, 以 `k` 打头,加上对应的描述

```c++
enum ReleaseType
{
    kReleaseUnkown = 0,
    kReleaseTimeout,
    kReleaseAddressErr,
    kReleaseSocketDisable,
    kReleaseTeardown,
    kReleaseResponseTimeout,
    kReleaseKillevent,
    kReleaseParseError,
    kReleaseByeBye
};
```

### 6.9 宏命名

- 全大写, 单词间用 `_` 分割

``` c++
#define ROUND(x) ...
#define PI_ROUNDED 3.0
```

## 7 注释

注释虽然写起来很痛苦, 但对保证代码可读性至关重要. 下面的规则描述了如何注释以及在哪儿注释. 当然也要记住: 注释固然很重要, 但最好的代码应当本身就是文档. 有意义的类型名和变量名, 要远胜过要用注释解释的含糊不清的名字.

你写的注释是给代码读者看的, 也就是下一个需要理解你的代码的人. 所以慷慨些吧, 下一个读者可能就是你!

- 单行注释使用 `//`, 多行注释使用 `/**/`

### 7.1 文件注释

- 在每一个文件开头加入版权公告.
- 法律公告和作者信息: 如果你对原始作者的文件做了重大修改, 请考虑删除原作者信息.
- 文件内容

  如果一个 `.h` 文件声明了多个概念, 则文件注释应当对文件的内容做一个大致的说明, 同时说明各概念之间的联系.
  一个一到两行的文件注释就足够了, 对于每个概念的详细文档应当放在各个概念中, 而不是文件注释中.
  不要在 `.h` 和 `.cc` 之间复制注释, 这样的注释偏离了注释的实际意义.

- 历史更改: 比较重大的更改应该在写上变更日期、变更内容、和作者

QtCreator 配置创建文件自动添加文件头注释:

1. 创建 LicenseTemplate 文件, 内容如下

    ```txt
    /*
    * 版权所有 Copyright © %YEAR% 司马大大(北京)智能系统有限公司 All Rights Reserved. BMI Technologies Co., Ltd..
    * -------------------------------------
    * filename    %FILENAME%
    * brief       添加摘要
    * author      %$USERNAME%
    * email       %$USEREMAIL%
    * date        %YEAR%-%MONTH%-%DAY%
    * description 添加描述
    * history     create on %YEAR%-%MONTH%-%DAY%
    */
    ```

    注意:

    - 请修改`默认邮箱`与作者(使用了环境变量, 如果环境变量未配置则会造成空输入)
    - 使用环境变量的值用 `%$Variable%`的格式

2. 在 QtCreator 中设定 LicenseTemplate

   - `选项`->
   - `工具`->`选项`->`C++`->`文件命名`
   - 文件命名中最下面一栏选择 LicenseTemplate

### 7.2 类注释

- 每个类的定义都要附带一份注释, 描述类的功能和用法, 除非它的功能相当明显.
- 类注释应当为读者理解如何使用与何时使用类提供足够的信息
- 如果类有任何同步前提, 请用文档说明.
- 如果该类的实例可被多线程访问, 要特别注意文档说明多线程环境下相关的规则和常量使用.

Qt 快捷键自动添加注释:

- 在类上方输入 `/**` 然后回车, 就会生成注释
- 如果需要添加使用示例, 手动增加 `@example` 字段

示例:

```c++
/**
 * @brief rtsp拉流器
 * @note  若通过SetReleaseCallback(ReleaseCallback callback), 设置了释放前的回调函数, 则需要创建者自己释放对象
 * @example
 *  CsRtspPuller pPuller = new CsRtspPuller("rtsp://192.168.1.104:10554/sVideo", "459827");
 *  if(pPuller->DoStartPull())
 *  {
 *      m_pRtspPuller->SetPullerRTPCallback(std::bind(&CsMTSTask::ProcessRecvData, this, std::placeholders::_1));
 *  }
 */
 class CsRtspPuller : public CsRtspClient
{
public:
    typedef std::function<void(CsRtpPacketPtr ptrRtpData)> ProcessRTPCallback;
public:
    CsRtspPuller(std::string strRtspUrl, std::string sessionId);
    virtual                         ~CsRtspPuller();
    void                            SetPullerRTPCallback(ProcessRTPCallback callback);
    bool                            DoStartPull();
    std::string                     GetVideoEncodeType();
}
```

### 7.3 函数注释

约定:

- 函数声明处的注释描述函数功能
- 定义处的注释描述函数实现.
- 函数的功能简单而明显时可以省略注释

示例:

```c++
/**
 * @brief   根据RtspState获得对应的字符串描述
 * @param   state : rtsp状态枚举
 * @return  rtsp状态对应的字符串描述
 */
std::string GetRtspStateString(RtspState state);
```

函数声明处的注释:

- 函数的输入输出.
- 对类成员函数而言: 函数调用期间对象是否需要保持引用参数, 是否会释放这些参数.
- 函数是否分配了必须由调用者释放的空间.
- 参数是否可以为空指针.
- 是否存在函数使用上的性能隐患.
- 如果函数是可重入的, 其同步前提是什么?

函数定义处如果内容过于复杂，或者比较难以理解地方应该加以说明。

Qt 快捷键自动添加注释:

- 在函数上方输入 `/**` 然后回车, 就会生成注释。

### 7.4 变量注释

通常变量名本身足以很好说明变量用途. 当变量名无法说明具体用途时应该加以注释。

### 7.5 实现注释

- 巧妙或复杂的代码段前要加注释。
- 比较隐晦或者难以理解的地方加入注释.
- 如果有多行的注释请把他们对齐。

### 7.6 TODO注释

- 对那些临时的, 短期的解决方案, 或已经够好但仍不完美的代码使用 `TODO` 注释.

### 7.7 弃用注释

- 通过弃用注释（`DEPRECATED` comments）以标记某接口点已弃用.

  您可以写上包含全大写的 `DEPRECATED` 的注释, 以标记某接口为弃用状态. 注释可以放在接口声明前, 或者同一行.

  在 `DEPRECATED` 一词后, 在括号中留下您的名字, 邮箱地址以及其他身份标识.
  
  弃用注释应当包涵简短而清晰的指引, 以帮助其他人修复其调用点. 在 C++ 中, 你可以将一个弃用函数改造成一个`内联函数`, 这一函数将调用新的接口.
  
  仅仅标记接口为 `DEPRECATED` 并不会让大家不约而同地弃用, 您还得亲自主动修正调用点（`callsites`）, 或是找个帮手.
  
  修正好的代码应该不会再涉及弃用接口点了, 着实改用新接口点. 如果您不知从何下手, 可以找标记弃用注释的当事人一起商量.

- API 弃用时在声明注释处用`@deprecated` 标出可替代的函数。

## 8 格式

### 行长度

- 每一行代码字符数不超过 80.
- 带有命令示例或 URL 的行可以超过 80 个字符.
- 包含长路径的 `#include` 语句可以超出 80 列.
- `头文件保护` 可以无视该原则.

### 非 ASCII 字符

- 尽量不使用非 ASCII 字符, 使用时必须使用 UTF-8 编码.

>google 原文[https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/formatting/](https://zh-google-styleguide.readthedocs.io/en/latest/google-cpp-styleguide/formatting/)

### 缩进

- `我们使用4个空格作为缩进, 如果你习惯使用Tab缩进, 请把你的编辑器的Tab修改为4个空格的缩进。`

### 函数声明与定义

- 返回类型和函数名在同一行, 参数也尽量放在同一行, 如果放不下就对`形参分行`, 分行方式与 `函数调用` 一致.

```c++
//正常
ReturnType ClassName::FunctionName(Type par_name1, Type par_name2)
{
  DoSomething();
  ...
}

//如果同一行文本太多, 放不下所有参数:
ReturnType ClassName::ReallyLongFunctionName(Type par_name1, Type par_name2,
                                             Type par_name3)
{
  DoSomething();
  ...
}

//甚至连第一个参数都放不下:
ReturnType LongClassName::ReallyReallyReallyLongFunctionName(
    Type par_name1,  // 4 space indent
    Type par_name2,
    Type par_name3)
{
    DoSomething();
  ...
}
```

未被使用的参数, 或者根据上下文很容易看出其用途的参数, 可以省略参数名:

```c++
void SetVal(int);
```

未被使用的参数如果其用途不明显的话, 在函数定义处将参数名注释起来:

```c++
void SetVal(int /*val*/);
```

属性, 和展开为属性的宏, 写在函数声明或定义的最前面, 即返回类型之前:

```c++
MUST_USE_RESULT bool IsOK();
```

### Lambda 表达式

Lambda 表达式对形参和函数体的格式化和其他函数一致; 捕获列表同理, 表项用逗号隔开.

若用引用捕获, 在变量名和 `&` 之间不留空格.

```c++
int x = 0;
auto add_to_x = [&x](int n) { x += n; };
```

### 函数调用

- 要么一行写完函数调用, 要么在圆括号里对参数分行, 要么参数另起一行且缩进四格.

  ```c++
  bool retval = DoSomething(argument1, argument2, argument3);
  bool retval = DoSomething(averyveryveryverylongargument1,
                            argument2, argument3);

  DoSomething(
          argument1, argument2,  // 4 空格缩进
          argument3, argument4);
  ```

- 如果一系列参数本身就有一定的结构, 可以酌情地按其结构来决定参数格式：

  ```c++
  my_widget.Transform(x1, x2, x3,
                      y1, y2, y3,
                      z1, z2, z3);
  ```

### if 与 else, while

不允许将以下写法

```c++  
if(x == 0) return false;

while(condition);
```

正确写法

```c++
if(x == 0)
    return false;
while(condition)
{
}
while(condition)
    continue;
```

### 布尔表达式

- 如果一个布尔表达式超过 标准行宽, 断行方式要统一一下.
  
下例中, 逻辑与 (&&) 操作符总位于行尾:

```c++
if (this_one_thing > this_other_thing &&
    a_third_thing == a_fourth_thing &&
    yet_another && last_one) {
  ...
}
```

### 函数返回值

- 不要在 return 表达式里加上非必须的圆括号.例如 `return (x);`

### 预处理指令

- 预处理指令不要缩进, 从行首开始.
- `#` 后不可以加空格

```c++
  if (lopsided_score) {
#if DISASTER_PENDING      // 正确 - 从行首开始
    DropEverything();
# if NOTIFY               // # 后不应该加空格
    NotifyClient();
# endif
#endif
    BackToNormal();
  }
```

### 构造函数初始值列表

- 构造函数初始化列表放在`同一行`或按四格缩进`并排多行`, `分隔符置于最前`, 分隔符后是否加空格不做要求。

```c++
CsRtspPuller::CsRtspPuller(std::string strRtspUrl, string sessionId)
    :CsRtspClient(strRtspUrl, sessionId)
    ,m_uSendBufferLen(0)
    ,m_bThreadRunState(true)
    ,m_bIsRecvTeardownResponse(false)
{
    string taskname ="csrtsppuller_";
    this->SetTaskName(taskname.c_str());
    m_threadProcessRTPData = std::thread(&CsRtspPuller::ProcessRTPDataInThread, this);
    memset(m_SendBuffer, 0 , 4096);
}

//或者例如构造函数在同一行
class Foo
{
public:
    Foo(Foo&& other) : m_fileid(other.field) {}

private:
    Field m_fileid;
};

```

### 命名空间格式化

- 命名空间内容不得缩进

```c++
namespace {

void foo() {  // 正确. 命名空间内没有额外的缩进.
  ...
}

}  // namespace
```

### 花括号格式化{}

- 除**命名空间与Lambda等特殊场景外**, 其余花括号开始都另起一行, 结束也另起一行

```c++
namespace bmi {

}//namespace bmi;

std::sort(vec.begin(), vec.end(), [](int a, int b) -> bool {
    return a < b;
});

if(x == 0)
{

}
else
{

}
while(x == 0)
{

}
for(int i = 0; i < 298; ++i)
{

}

class Base
{
    Base()
    {

    }
};

```

### 水平留白

- 每个分隔符后都添加水平留白

```c++
for(int i = 0; i < 10; ++i)
{

}
function(a, b, c, d);
```

- 赋值运算符前后总是有空格.

```c++
x = 1;
```

- 其它二元操作符也前后恒有空格, 不过对于表达式的子式可以不加空格.

```c++
v = w * x + y / z;
//或者
v = w*x + y/z;
```

- 圆括号内部没有紧邻空格.

```c++
v = w * (x + z)
```

- 在参数和一元操作符之间不加空格.

```c++
++x;
if(x && !y)
 ...
```

- 命名空间左括号前加入水平留白

```c++
namespace bmi {

}//namespace bmi
```

### '弃用'标注

- 项目定义宏: `#define attribute_deprecated __attribute__((deprecated))`
- 在弃用的API或者变量的声明处用 `attribute_deprecated` 宏来标记
- 弃用的函数注释处使用 `@deprecated` 标记出被哪个函数所替代。

```c++
namespace bmi {
/**
 * @brief
 * @deprecated 被getname123替代
 */
attribute_deprecated void getname();

}//namespace bmi
```
