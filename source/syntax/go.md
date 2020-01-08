# Go 风格指南

```text
作者: kiki
日期: 2020/1/7
```

参考 [Uber Go 风格指南(译)](https://www.bookstack.cn/read/uber-go-guide/style.md)。

## 介绍

风格是指规范代码的共同约定。`风格`一词其实是有点用词不当的，因为共同约定的范畴远远不止 gofmt 所做的源代码格式化这些。

本文档许多是 Go 的通用准则，而其他扩展准则依赖于依赖于外部资源：

1. [Effective Go](https://golang.org/doc/effective_go.html)
2. [The Go common mistakes guide](https://github.com/golang/go/wiki/CodeReviewComments)

所有代码都应该通过 `golint` 和 `go vet` 的检查并无错误。建议将编辑器设置为：

- 保存时运行 `goimports`
- 运行 `golint` 和 `go vet` 检查错误

可以在这找到关于编辑器设定 Go tools 的相关信息：
<https://github.com/golang/go/wiki/IDEsAndTextEditorPlugins>

## 指导原则

### 指向 interface 的指针

你几乎不需要指向接口的指针。你应该直接将接口作为值传递，因为传递的底层数据就是指针。

接口实质上在底层用两个字段表示：

1. 一个指向某些特定类型信息的指针。可将其视为 "type" (类型指针)。
2. 数据指针。如果存储的数据是指针，则直接存储。如果存储的数据是一个值，则存储指向该值的指针。

如果希望接口方法修改底层数据，则必须将指针数据传递给接口。

### 接收器与接口

具有值类型接收器的方法可以被值类型和指针类型调用。

例如，

```go
type S struct {
  data string
}

func (s S) Read() string {
  return s.data
}

func (s *S) Write(str string) {
  s.data = str
}

sVals := map[int]S{1: {"A"}}

// 你只能通过值调用 Read
sVals[1].Read()

// 这不能编译通过：
//  sVals[1].Write("test")

sPtrs := map[int]*S{1: {"A"}}

// 通过指针既可以调用 Read，也可以调用 Write 方法
sPtrs[1].Read()
sPtrs[1].Write("test")
```

同样，即使该方法具有值接收器，接口也可以通过指针来满足调用需求。

```go
type F interface {
  f()
}

type S1 struct{}

func (s S1) f() {}

type S2 struct{}

func (s *S2) f() {}

s1Val := S1{}
s1Ptr := &S1{}
s2Val := S2{}
s2Ptr := &S2{}

var i F
i = s1Val
i = s1Ptr
i = s2Ptr

//  下面代码无法通过编译。因为 s2Val 是一个值，而 S2 的 f 方法中没有使用值接收器
//   i = s2Val
```

[Effective Go](https://golang.org/doc/effective_go.html) 中有一段关于 [pointers vs. values](https://golang.org/doc/effective_go.html#pointers_vs_values) 的精彩讲解。

### 零值 Mutex 是有效的

零值 `sync.Mutex` 和 `sync.RWMutex` 是有效的。所以基本不需要指向 mutex 的指针。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
mu := new(sync.Mutex)
mu.Lock()
```

</td><td>

```go
var mu sync.Mutex
mu.Lock()
```

</td></tr>
</tbody></table>

如果你希望通过指针操作结构体，mutex 可以作为其非指针结构体字段，或者最好直接嵌入结构体中。

<table>
<tbody>
<tr><td>

```go
type smap struct {
  sync.Mutex // 仅适用于非导出类型

  data map[string]string
}

func newSMap() *smap {
  return &smap{
    data: make(map[string]string),
  }
}

func (m *smap) Get(k string) string {
  m.Lock()
  defer m.Unlock()

  return m.data[k]
}
```

</td><td>

```go
type SMap struct {
  mu sync.Mutex

  data map[string]string
}

func NewSMap() *SMap {
  return &SMap{
    data: make(map[string]string),
  }
}

func (m *SMap) Get(k string) string {
  m.mu.Lock()
  defer m.mu.Unlock()

  return m.data[k]
}
```

</td></tr>

</tr>
<tr>
<td>嵌入到非导出类型或者需要实现 Mutex 接口的类型。</td>
<td>对于导出类型，将 mutex 作为私有成员变量。</td>
</tr>

</tbody></table>

### 在边界处拷贝 Slices 和 Maps

slice 和 map 包含了指向底层数据的指针，因此在需要复制它们时要特别注意。

#### 接收 Slices 和 Maps

请记住，如果存储了对 slice 和 map 的引用，用户可以对作为参数传入的 slice 或 map 进行修改。

<table>
<thead><tr><th>Bad</th> <th>Good</th></tr></thead>
<tbody>
<tr>
<td>

```go
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = trips
}

trips := ...
d1.SetTrips(trips)

// 你是要修改 d1.trips 吗？
trips[0] = ...
```

</td>
<td>

```go
func (d *Driver) SetTrips(trips []Trip) {
  d.trips = make([]Trip, len(trips))
  copy(d.trips, trips)
}

trips := ...
d1.SetTrips(trips)

// 我们现在可以修改 trips[0]，但不会影响到 d1.trips
trips[0] = ...
```

</td>
</tr>

</tbody>
</table>

#### 返回 slices 或 maps

同样，请注意用户对暴露内部状态的 map 或 slice 的修改。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
type Stats struct {
  mu sync.Mutex

  counters map[string]int
}

// Snapshot 返回当前状态
func (s *Stats) Snapshot() map[string]int {
  s.mu.Lock()
  defer s.mu.Unlock()

  return s.counters
}

// snapshot 不再受互斥锁保护
// 因此对 snapshot 的任何访问都将受到数据竞争的影响
// 影响 stats.counters
snapshot := stats.Snapshot()
```

</td><td>

```go
type Stats struct {
  mu sync.Mutex

  counters map[string]int
}

func (s *Stats) Snapshot() map[string]int {
  s.mu.Lock()
  defer s.mu.Unlock()

  result := make(map[string]int, len(s.counters))
  for k, v := range s.counters {
    result[k] = v
  }
  return result
}

// snapshot 现在是一个拷贝
snapshot := stats.Snapshot()
```

</td></tr>
</tbody></table>

### 使用 defer 释放资源

使用 defer 释放资源，诸如文件和锁。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
p.Lock()
if p.count < 10 {
  p.Unlock()
  return p.count
}

p.count++
newCount := p.count
p.Unlock()

return newCount

// 当有多个 return 时，很容易遗忘 unlock
```

</td><td>

```go
p.Lock()
defer p.Unlock()

if p.count < 10 {
  return p.count
}

p.count++
return p.count

// 可读性更高
```

</td></tr>
</tbody></table>

defer 的开销非常小，只有你能证明你的函数执行时间在纳秒级别时才可以不使用它。使用 defer 提升可读性是值得的，因为使用它们的成本微不足道。特别是在一些主要是做内存操作的长函数中，函数中的其他计算操作远比 `defer` 重要。

### Channel 的大小是 1 还是 None

channel 的大小通常应为 1 或是无缓冲的。默认情况下，channel 是无缓冲的，大小为零。任何其他尺寸都必须经过严格的审查。认真考虑如何确定其大小，是什么阻止了工作中的通道被填满并阻塞了写入操作，我们需要考虑如何确定大小，以及何种情况会发生这样的现象。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// 足以满足任何人！
c := make(chan int, 64)
```

</td><td>

```go
// 大小为 1
c := make(chan int, 1) // 或
// 无缓冲 channel，大小为 0
c := make(chan int)
```

</td></tr>
</tbody></table>

### 枚举从 1 开始

在 Go 中使用枚举的标准方法是声明一个自定义类型并通过 iota 关键字来声明一个 const 组。由于 Go 中变量的默认值都为该类型的零值，所以枚举变量的值应该从非零值开始。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
type Operation int

const (
  Add Operation = iota
  Subtract
  Multiply
)

// Add=0, Subtract=1, Multiply=2
```

</td><td>

```go
type Operation int

const (
  Add Operation = iota + 1
  Subtract
  Multiply
)

// Add=1, Subtract=2, Multiply=3
```

</td></tr>
</tbody></table>

在某些情况下，使用零值是有意义的(枚举从零开始).例如，当零值是我们期望的默认行为时。

```go
type LogOutput int

const (
  LogToStdout LogOutput = iota
  LogToFile
  LogToRemote
)

// LogToStdout=0, LogToFile=1, LogToRemote=2
```

### 错误类型

Go 中有多种声明错误 errors：

- [`errors.New`] 声明简单的静态字符串错误信息
- [`fmt.Errorf`] 声明格式化的字符串错误信息
- 为自定义类型实现 `Error()` 方法
- 通过 [`"pkg/errors".Wrap`] 的封装错误类型

返回错误时，请考虑以下因素以作出最佳选择：

- 这是一个不需要额外信息的简单错误吗？如果是，使用 [`errors.New`]。
- 客户需要检测并处理此错误吗？如果是，则应使用自定义类型，并实现 `Error()` 方法。
- 是否正在传播下游函数返回的错误？如果是，请查看本文后面有关 [Error 封装](#Error-封裝) 部分的内容。
- 其他，使用 [`fmt.Errorf`]。

  [`errors.New`]: https://golang.org/pkg/errors/#New
  [`fmt.Errorf`]: https://golang.org/pkg/fmt/#Errorf
  [`"pkg/errors".Wrap`]: https://godoc.org/github.com/pkg/errors#Wrap

如果客户需要检测错误，并且是通过 [`errors.New`] 创建的一个简单的错误，请使用 `var` 声明这个错误类型。。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// package foo

func Open() error {
  return errors.New("could not open")
}

// package bar

func use() {
  if err := foo.Open(); err != nil {
    if err.Error() == "could not open" {
      // handle
    } else {
      panic("unknown error")
    }
  }
}
```

</td><td>

```go
// package foo

var ErrCouldNotOpen = errors.New("could not open")

func Open() error {
  return ErrCouldNotOpen
}

// package bar

if err := foo.Open(); err != nil {
  if err == foo.ErrCouldNotOpen {
    // handle
  } else {
    panic("unknown error")
  }
}
```

</td></tr>
</tbody></table>

如果你有一个错误需要客户端来检测，并且想向其添加更多信息(例如，它不是静态字符串)，则应使用自定义类型。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
func open(file string) error {
  return fmt.Errorf("file %q not found", file)
}

func use() {
  if err := open(); err != nil {
    if strings.Contains(err.Error(), "not found") {
      // handle
    } else {
      panic("unknown error")
    }
  }
}
```

</td><td>

```go
type errNotFound struct {
  file string
}

func (e errNotFound) Error() string {
  return fmt.Sprintf("file %q not found", e.file)
}

func open(file string) error {
  return errNotFound{file: file}
}

func use() {
  if err := open(); err != nil {
    if _, ok := err.(errNotFound); ok {
      // handle
    } else {
      panic("unknown error")
    }
  }
}
```

</td></tr>
</tbody></table>

直接导出自定义错误类型时要小心，因为它们已成为程序包公共 API 的一部分。最好公开一个匹配函数来检查错误。

```go
// package foo

type errNotFound struct {
  file string
}

func (e errNotFound) Error() string {
  return fmt.Sprintf("file %q not found", e.file)
}

func IsNotFoundError(err error) bool {
  _, ok := err.(errNotFound)
  return ok
}

func Open(file string) error {
  return errNotFound{file: file}
}

// package bar

if err := foo.Open("foo"); err != nil {
  if foo.IsNotFoundError(err) {
    // handle
  } else {
    panic("unknown error")
  }
}
```

### Error 封裝

一个函数/方法调用失败时，有三种主要的错误传播方式：

- 如果想要维护原始错误类型并且不需要添加额外的上下文信息，则返回原始错误。
- 使用 [`"pkg/errors".Wrap`] 添加上下文，以便返回的错误信息包含更多上下文，并且可通过 [`"pkg/errors".Cause`] 提取原始错误信息。
- 如果调用者不需要检测或处理的特定错误情况，使用 [`fmt.Errorf`]。

建议在可能的地方添加上下文，以获得诸如 “failed to call service foo: connection refused” 之类的更有用的错误信息，而不是诸如 “connection refused” 之类的模糊错误信息。

在将上下文添加到返回的错误时，请避免使用 “failed to” 之类的短语来保持上下文简洁，这些短语会陈述明显的内容，并且会随着错误在堆栈中的传递而逐渐堆积：

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
s, err := store.New()
if err != nil {
    return fmt.Errorf(
        "failed to create new store: %s", err)
}
```

</td><td>

```go
s, err := store.New()
if err != nil {
    return fmt.Errorf(
        "new store: %s", err)
}
```

<tr><td>

```txt
failed to x: failed to y: failed to create new store: the error
```

</td><td>

```txt
x: y: new store: the error
```

</td></tr>
</tbody></table>

但是，如果这个错误信息是会被发送到另一个系统时，必须清楚的表明这是一个错误(例如日志中 `err` 标签或者 `Failed` 前缀)。

另见 [Don't just check errors, handle them gracefully]。不要只是检查错误，要优雅地处理错误。

  [`"pkg/errors".Cause`]: https://godoc.org/github.com/pkg/errors#Cause
  [Don't just check errors, handle them gracefully]: https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully

### BMI 错误信息添加上下文

在添加上下文信息时建议使用 `[fileName-funcName-{filed1:value1, filed2:value2}]`，
并使用 `github.com/pkg/errors` 包的 `Wrapf` 方法进行包装,方便搜索及解析原始错误信息。

例如:

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
s, err := db.Insert(book)
if err != nil {
  return errors.Wrapf(err,
    "book newBook Title:%s insert book",
    book.Title)
}
```

</td><td>

```go
s, err := db.Insert(book)
if err != nil {
  return errors.Wrapf(err,
    "[book-newBook-{Title:%s}] insert book",
    book.Title)
}
```

</tbody></table>

### 处理类型断言失败

[type assertion] 的单返回值形式在遇到类型错误时会直接 panic。因此，请始终使用 “comma ok” 的惯用方法。

  [type assertion]: https://golang.org/ref/spec#Type_assertions

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
t := i.(string)
```

</td><td>

```go
t, ok := i.(string)
if !ok {
  // 优雅地处理错误
}
```

</td></tr>
</tbody></table>

### 不要 panic

在生产环境中运行的代码必须避免出现 panic。panic 是级联故障 ([cascading failures]) 的主要根源 。如果发生错误，该函数必须返回错误，并允许调用者决定如何处理它。

  [cascading failures]: https://en.wikipedia.org/wiki/Cascading_failure

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
func foo(bar string) {
  if len(bar) == 0 {
    panic("bar must not be empty")
  }
  // ...
}

func main() {
  if len(os.Args) != 2 {
    fmt.Println("USAGE: foo <bar>")
    os.Exit(1)
  }
  foo(os.Args[1])
}
```

</td><td>

```go
func foo(bar string) error {
  if len(bar) == 0 {
    return errors.New("bar must not be empty")
  }
  // ...
  return nil
}

func main() {
  if len(os.Args) != 2 {
    fmt.Println("USAGE: foo <bar>")
    os.Exit(1)
  }
  if err := foo(os.Args[1]); err != nil {
    panic(err)
  }
}
```

</td></tr>
</tbody></table>

panic/recover 并不是错误处理策略。仅当发生不可恢复的事情(例如：nil 引用)时，程序才必须 panic。程序初始化是一个例外：程序启动时遇到需要终止执行的错误可能会 panic。

```go
var _statusTemplate = template.Must(template.New("name").Parse("_statusHTML"))
```

即使在测试中，也优先使用 `t.Fatal` 或者 `t.FailNow` 而不是 panic，以确保测试标记为失败。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// func TestFoo(t *testing.T)

f, err := ioutil.TempFile("", "test")
if err != nil {
  panic("failed to set up test")
}
```

</td><td>

```go
// func TestFoo(t *testing.T)

f, err := ioutil.TempFile("", "test")
if err != nil {
  t.Fatal("failed to set up test")
}
```

</td></tr>
</tbody></table>

<!-- TODO: Explain how to use _test packages. -->

### 使用 go.uber.org/atomic

Go 的 [sync/atomic] 包仅仅提供针对原始类型 (`int32`, `int64` 等)的原子操作。因此，很容易忘记使用原子操作来读写变量。

[go.uber.org/atomic] 通过隐藏基础类型为这些操作增加了类型安全性。此外，它包括一个方便的`atomic.Bool`类型。

  [go.uber.org/atomic]: https://godoc.org/go.uber.org/atomic
  [sync/atomic]: https://golang.org/pkg/sync/atomic/

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
type foo struct {
  running int32  // atomic
}

func (f* foo) start() {
  if atomic.SwapInt32(&f.running, 1) == 1 {
     // already running…
     return
  }
  // start the Foo
}

func (f *foo) isRunning() bool {
  return f.running == 1  // race!
}
```

</td><td>

```go
type foo struct {
  running atomic.Bool
}

func (f *foo) start() {
  if f.running.Swap(true) {
     // already running…
     return
  }
  // start the Foo
}

func (f *foo) isRunning() bool {
  return f.running.Load()
}
```

</td></tr>
</tbody></table>

### 避免可变全局变量

使用选择依赖注入方式避免改变全局变量。这既适用于函数指针又适用于其他值类型。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// sign.go
var _timeNow = time.Now
func sign(msg string) string {
  now := _timeNow()
  return signWithTime(msg, now)
}
```

</td><td>

```go
// sign.go
type signer struct {
  now func() time.Time
}
func newSigner() *signer {
  return &signer{
    now: time.Now,
  }
}
func (s *signer) Sign(msg string) string {
  now := s.now()
  return signWithTime(msg, now)
}
```

</td></tr>
<tr><td>

```go
// sign_test.go
func TestSign(t *testing.T) {
  oldTimeNow := _timeNow
  _timeNow = func() time.Time {
    return someFixedTime
  }
  defer func() { _timeNow = oldTimeNow }()
  assert.Equal(t, want, sign(give))
}
```

</td><td>

```go
// sign_test.go
func TestSigner(t *testing.T) {
  s := newSigner()
  s.now = func() time.Time {
    return someFixedTime
  }
  assert.Equal(t, want, s.Sign(give))
}
```

</td></tr>
</tbody></table>

## 性能

性能方面的特定准则只适用于高频场景。

### 优先使用 strconv 而不是 fmt

将原语转换为字符串或从字符串转换时，`strconv` 速度比 `fmt` 快。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
for i := 0; i < b.N; i++ {
  s := fmt.Sprint(rand.Int())
}
```

</td><td>

```go
for i := 0; i < b.N; i++ {
  s := strconv.Itoa(rand.Int())
}
```

</td></tr>
<tr><td>

```txt
BenchmarkFmtSprint-4    143 ns/op    2 allocs/op
```

</td><td>

```txt
BenchmarkStrconv-4    64.2 ns/op    1 allocs/op
```

</td></tr>
</tbody></table>

### 避免 string-to-byte 的转换

不要反复从字符串字面量创建 byte 切片。相反，执行一次转换后存储结果供后续使用。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
for i := 0; i < b.N; i++ {
  w.Write([]byte("Hello world"))
}
```

</td><td>

```go
data := []byte("Hello world")
for i := 0; i < b.N; i++ {
  w.Write(data)
}
```

</tr>
<tr><td>

```txt
BenchmarkBad-4   50000000   22.2 ns/op
```

</td><td>

```txt
BenchmarkGood-4  500000000   3.25 ns/op
```

</td></tr>
</tbody></table>

### 尽量初始化时指定 Map 容量

在尽可能的情况下，在使用 `make()` 初始化的时候提供容量信息。

```go
make(map[T1]T2, hint)
```

提供容量信息 hint 给 `make()` 尝试在初始化时调整 map 大小，这减少了在将元素添加到 map 时增长和分配的开销。注意，map 不能保证分配 hint 个容量。因此，即使提供了容量，添加元素仍然可能进行分配。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
m := make(map[string]os.FileInfo)

files, _ := ioutil.ReadDir("./files")
for _, f := range files {
    m[f.Name()] = f
}
```

</td><td>

```go

files, _ := ioutil.ReadDir("./files")

m := make(map[string]os.FileInfo, len(files))
for _, f := range files {
    m[f.Name()] = f
}
```

</td></tr>
<tr><td>

`m` 是在没有大小提示的情况下创建的；在运行时可能会有更多分配。

</td><td>

`m` 是有大小提示创建的；在运行时可能会有更少的分配。

</td></tr>
</tbody></table>

## 代码风格

### 一致性

本文中概述的一些标准都是客观性的评估，是根据场景、上下文、或者主观性的判断；

但是最重要的是，**保持一致**.

一致性的代码更易维护和解释，需要更少的学习成本。并且当出现新约定或者修复错误后更容易迁移或更新。

相反，一个代码库内包含多种不同的或冲突的风格会导致增加维护成本、不确定性和认知失调。所有这些都会直接导致速度降低、代码审查痛苦，以及更多 bug。

将这些标准应用于一个代码库时，建议在 package (或更大)级别进行更改：对子包级别的应用会引入多个风格到同一代码中，违反了上述关注点。

### 声明分组

Go 语言支持将相似的声明分组：

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
import "a"
import "b"
```

</td><td>

```go
import (
  "a"
  "b"
)
```

</td></tr>
</tbody></table>

分组同样适用于常量、变量和类型的声明：

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go

const a = 1
const b = 2

var a = 1
var b = 2

type Area float64
type Volume float64
```

</td><td>

```go
const (
  a = 1
  b = 2
)

var (
  a = 1
  b = 2
)

type (
  Area float64
  Volume float64
)
```

</td></tr>
</tbody></table>

仅将相关的声明放在一组。不要将不相关的声明放在一组。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
type Operation int

const (
  Add Operation = iota + 1
  Subtract
  Multiply
  ENV_VAR = "MY_ENV"
)
```

</td><td>

```go
type Operation int

const (
  Add Operation = iota + 1
  Subtract
  Multiply
)

const ENV_VAR = "MY_ENV"
```

</td></tr>
</tbody></table>

声明分组可以在任意位置使用。例如，可以在函数内部使用：

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
func f() string {
  var red = color.New(0xff0000)
  var green = color.New(0x00ff00)
  var blue = color.New(0x0000ff)

  ...
}
```

</td><td>

```go
func f() string {
  var (
    red   = color.New(0xff0000)
    green = color.New(0x00ff00)
    blue  = color.New(0x0000ff)
  )

  ...
}
```

</td></tr>
</tbody></table>

### import 组内顺序

import 有两类导入组：

- 标准库
- 其他库

下边是 goimports 默认的分组。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
import (
  "fmt"
  "os"
  "go.uber.org/atomic"
  "golang.org/x/sync/errgroup"
)
```

</td><td>

```go
import (
  "fmt"
  "os"

  "go.uber.org/atomic"
  "golang.org/x/sync/errgroup"
)
```

</td></tr>
</tbody></table>

### 包命名

当为包命名时，请注意如下事项：

- 字符全部小写。没有大写或下划线。
- 在大多数情况下引入包不需要去重命名。
- 简单明了，命名需要能够在被导入的地方准确识别。
- 不要使用复数。例如，net/url, 而不是 net/urls。
- 不要用 “common”、“util”、“shared” 或 “lib”。这些都是不好的，表达信息不明的名称

另见 [Package Names] 和 [Go 包样式指南]。

  [Package Names]: https://blog.golang.org/package-names
  [Go 包样式指南]: https://rakyll.org/style-packages/

### 函数命名

我们遵循 Go 社区关于使用 [MixedCaps 作为函数名] 的约定。有一个例外，对相关的测试用例进行分组时，函数名可能包含下划线，如：`TestMyFunction_WhatIsBeingTested`.

  [MixedCaps 作为函数名]: https://golang.org/doc/effective_go.html#mixed-caps

### BMI 变量及常量命名等

golang 推荐使用驼峰命名法来命名变量，常量，方法及结构体等。

### 导入别名

如果包的名称与导入路径的最后一个元素不匹配，那必须使用导入别名。

```go
import (
  "net/http"

  client "example.com/client-go"
  trace "example.com/trace/v2"
)
```

在其他情况下，除非导入的包名之间有直接冲突，否则应避免使用导入别名。
<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
import (
  "fmt"
  "os"

  nettrace "golang.net/x/trace"
)
```

</td><td>

```go
import (
  "fmt"
  "os"
  "runtime/trace"

  nettrace "golang.net/x/trace"
)
```

</td></tr>
</tbody></table>

### BMI receiver 命名

- golang 中存在receiver 的概念 receiver 名称应该尽量保持一致，并尽量简略。避免this, super, self 等其他语言的一些语义。
- 对同一结构体指针与值的接受者名称尽量统一。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
type something struct{ ... }

func (this *something) Stop() {...}
```

</td><td>

```go
type something struct{ ... }

func (s *something) Stop() {...}
```

</td></tr>
</tbody></table>

### 函数分组与顺序

- 函数应该粗略的按照调用顺序来排布。
- 同一文件中的函数应按接收者分组。

因此，导出的函数应排在文件首，放在 `struct`、`const`、`var` 定义之后。

 `newXYZ()`/`NewXYZ()` 之类的函数应该排布在声明类型之后，具有接收器的其余方法之前。

因为函数是按接收器类别分组的，所以普通工具函数应排布在文件末尾。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
func (s *something) Cost() {
  return calcCost(s.weights)
}

type something struct{ ... }

func calcCost(n []int) int {...}

func (s *something) Stop() {...}

func newSomething() *something {
    return &something{}
}
```

</td><td>

```go
type something struct{ ... }

func newSomething() *something {
    return &something{}
}

func (s *something) Cost() {
  return calcCost(s.weights)
}

func (s *something) Stop() {...}

func calcCost(n []int) int {...}
```

</td></tr>
</tbody></table>

### 减少嵌套

代码应该通过尽可能地先处理错误情况/特殊情况，并且及早返回或继续下一循环来减少嵌套。尽量减少嵌套于多个级别的代码数量。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
for _, v := range data {
  if v.F1 == 1 {
    v = process(v)
    if err := v.Call(); err == nil {
      v.Send()
    } else {
      return err
    }
  } else {
    log.Printf("Invalid v: %v", v)
  }
}
```

</td><td>

```go
for _, v := range data {
  if v.F1 != 1 {
    log.Printf("Invalid v: %v", v)
    continue
  }

  v = process(v)
  if err := v.Call(); err != nil {
    return err
  }
  v.Send()
}
```

</td></tr>
</tbody></table>

### 不必要的 else

如果一个变量在 if 的两个分支中都设置了，那应该使用单个 if。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
var a int
if b {
  a = 100
} else {
  a = 10
}
```

</td><td>

```go
a := 10
if b {
  a = 100
}
```

</td></tr>
</tbody></table>

### 顶层变量声明

在顶层使用标准 `var` 关键字声明变量时，不要显式指定类型，除非它与表达式的返回类型不同。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
var _s string = F()

func F() string { return "A" }
```

</td><td>

```go
var _s = F()
// F 已经明确声明返回一个字符串类型，因此我们没有必要显式指定 _s 的类型

func F() string { return "A" }
```

</td></tr>
</tbody></table>

如果表达式的返回类型与所需的类型不完全匹配，请显示指定类型。

```go
type myError struct{}

func (myError) Error() string { return "error" }

func F() myError { return myError{} }

var _e error = F()
// F 返回一个 myError 类型的实例，但是我们要 error 类型
```

### 非导出的全局变量和常量以 _ 开头

非导出的包内全局变量 `var` 和常量 `const`，前面加上前缀 `_`，以明确表示它们是全局符号。

例外：未导出的错误类型变量，应以 `err` 开头。

解释：非导出的顶级(全局)变量和常量具有包范围作用域。使用通用名称命名，很容易导致在其他文件中意外使用错误的值。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// foo.go

const (
  defaultPort = 8080
  defaultUser = "user"
)

// bar.go

func Bar() {
  defaultPort := 9090
  ...
  fmt.Println("Default port", defaultPort)

  // We will not see a compile error if the first line of
  // Bar() is deleted.
}
```

</td><td>

```go
// foo.go

const (
  _defaultPort = 8080
  _defaultUser = "user"
)
```

</td></tr>
</tbody></table>

### 结构体中的嵌入类型

嵌入式类型(例如 mutex) 应位于结构体内的字段列表的顶部，并且必须以一个空行与常规字段分隔开。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
type Client struct {
  version int
  http.Client
}
```

</td><td>

```go
type Client struct {
  http.Client

  version int
}
```

</td></tr>
</tbody></table>

### 使用字段名初始化结构体

初始化结构体时，几乎始终应该指定字段名称。[`go vet`] 格式化时会强制执行这个操作。

  [`go vet`]: https://golang.org/cmd/vet/

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
k := User{"John", "Doe", true}
```

</td><td>

```go
k := User{
    FirstName: "John",
    LastName: "Doe",
    Admin: true,
}
```

</td></tr>
</tbody></table>

例外：在测试表中，如果结构体只有 3 个或更少的字段，则可以省略字段名称。

```go
tests := []struct{
  op Operation
  want string
}{
  {Add, "add"},
  {Subtract, "subtract"},
}
```

### 局部变量声明

如果声明局部变量时需要明确设值，应使用短变量声明形式 (`:=`)。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
var s = "foo"
```

</td><td>

```go
s := "foo"
```

</td></tr>
</tbody></table>

但是，在某些情况下，使用 `var` 关键字声明变量，默认的初始化值会更清晰。例如，[声明空切片]。

  [声明空切片]: https://github.com/golang/go/wiki/CodeReviewComments#declaring-empty-slices

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
func f(list []int) {
  filtered := []int{}
  for _, v := range list {
    if v > 10 {
      filtered = append(filtered, v)
    }
  }
}
```

</td><td>

```go
func f(list []int) {
  var filtered []int
  for _, v := range list {
    if v > 10 {
      filtered = append(filtered, v)
    }
  }
}
```

</td></tr>
</tbody></table>

### nil 是一个有效的 slice

`nil` 是一个有效的长度为 0 的 slice，这意味着，

- 不应明确返回长度为零的切片。而应该直接返回 `nil`

  <table>
  <thead><tr><th>Bad</th><th>Good</th></tr></thead>
  <tbody>
  <tr><td>

  ```go
  if x == "" {
    return []int{}
  }
  ```

  </td><td>

  ```go
  if x == "" {
    return nil
  }
  ```

  </td></tr>
  </tbody></table>

- 若要检查切片是否为空，请始终使用 `len(s) == 0`，不要与 `nil` 比较来检查。

  <table>
  <thead><tr><th>Bad</th><th>Good</th></tr></thead>
  <tbody>
  <tr><td>

  ```go
  func isEmpty(s []string) bool {
    return s == nil
  }
  ```

  </td><td>

  ```go
  func isEmpty(s []string) bool {
    return len(s) == 0
  }
  ```

  </td></tr>
  </tbody></table>

- 零值切片(用 `var` 声明的切片)可立即使用，无需调用 `make()` 创建。

  <table>
  <thead><tr><th>Bad</th><th>Good</th></tr></thead>
  <tbody>
  <tr><td>

  ```go
  nums := []int{}
  // or, nums := make([]int)

  if add1 {
    nums = append(nums, 1)
  }

  if add2 {
    nums = append(nums, 2)
  }
  ```

  </td><td>

  ```go
  var nums []int

  if add1 {
    nums = append(nums, 1)
  }

  if add2 {
    nums = append(nums, 2)
  }
  ```

  </td></tr>
  </tbody></table>

### 缩小变量作用域

如有可能，尽量缩小变量作用范围。除非它与 [减少嵌套](#减少嵌套) 的规则冲突。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
err := ioutil.WriteFile(name, data, 0644)
if err != nil {
 return err
}
```

</td><td>

```go
if err := ioutil.WriteFile(name, data, 0644); err != nil {
 return err
}
```

</td></tr>
</tbody></table>

如果需要在 if 之外使用函数调用的结果，则不应尝试缩小范围。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
if data, err := ioutil.ReadFile(name); err == nil {
  err = cfg.Decode(data)
  if err != nil {
    return err
  }

  fmt.Println(cfg)
  return nil
} else {
  return err
}
```

</td><td>

```go
data, err := ioutil.ReadFile(name)
if err != nil {
   return err
}

if err := cfg.Decode(data); err != nil {
  return err
}

fmt.Println(cfg)
return nil
```

</td></tr>
</tbody></table>

### 避免裸参数

函数调用中的裸参数可能会降低代码可读性。所以当参数名称的含义不明显时，请为参数添加 C 样式注释 (`/* ... */`)

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// func printInfo(name string, isLocal, done bool)

printInfo("foo", true, true)
```

</td><td>

```go
// func printInfo(name string, isLocal, done bool)

printInfo("foo", true /* isLocal */, true /* done */)
```

</td></tr>
</tbody></table>

上面更好的作法是将 `bool` 类型换成自定义类型，从而使代码更易读且类型安全。将来需要拓展时，该参数也可以不止两个状态(true/false)。

```go
type Region int

const (
  UnknownRegion Region = iota
  Local
)

type Status int

const (
  StatusReady = iota + 1
  StatusDone
  // Maybe we will have a StatusInProgress in the future.
)

func printInfo(name string, region Region, status Status)
```

### 使用原始字符串字面值，避免转义

Go 支持使用 [原始字符串字面值](https://golang.org/ref/spec#raw_string_lit)，即使用反引号表示原生字符串，可以多行并包含引号。使用它可以避免使用肉眼阅读较为困难的手工转义的字符串。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
wantError := "unknown name:\"test\""
```

</td><td>

```go
wantError := `unknown error:"test"`
```

</td></tr>
</tbody></table>

### 初始化结构体引用

在初始化结构引用时，请使用 `&T{}` 代替 `new(T)`，以使其与结构体初始化方式保持一致。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
sval := T{Name: "foo"}

// inconsistent
sptr := new(T)
sptr.Name = "bar"
```

</td><td>

```go
sval := T{Name: "foo"}

sptr := &T{Name: "bar"}
```

</td></tr>
</tbody></table>

### 初始化 Maps

对于空 map 使用 `make(..)`，并且 map 是随着代码初始化数据。这使得 map 初始化与声明直观上不同，并且在 可以获得容量时易于增加 map 容量参数。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
var (
  // m1 读写安全;
  // m2 在写入时会 panic
  m1 = map[T1]T2{}
  m2 map[T1]T2
)
```

</td><td>

```go
var (
  // m1 读写安全;
  // m2 在写入时会 panic
  m1 = make(map[T1]T2)
  m2 map[T1]T2
)
```

</td></tr>
<tr><td>

声明和初始化看起来非常相似。

</td><td>

声明和初始化看起来差别非常大。

</td></tr>
</tbody></table>

尽可能的在初始化时提供 map 容量，详细请看 [尽量初始化时指定 Map 容量](#尽量初始化时指定-Map-容量)。

另外，如果 map 拥有固定的元素列表，则使用 map 字面量(初始化列表)进行初始化。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
m := make(map[T1]T2, 3)
m[k1] = v1
m[k2] = v2
m[k3] = v3
```

</td><td>

```go
m := map[T1]T2{
  k1: v1,
  k2: v2,
  k3: v3,
}
```

</td></tr>
</tbody></table>

基本准则是：当在初始化时增加固定的元素列表时，使用 map 字面量。否则，使用 `make` (且如果可以，指定容量)。

### 格式化字符串放在 Printf 外部

如果你为 `Printf`-style 函数声明格式字符串，将格式化字符串放在函数外面，并将其设置为 `const` 常量。

这有助于`go vet`工具对格式字符串执行静态分析。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
msg := "unexpected values %v, %v\n"
fmt.Printf(msg, 1, 2)
```

</td><td>

```go
const msg = "unexpected values %v, %v\n"
fmt.Printf(msg, 1, 2)
```

</td></tr>
</tbody></table>

### 为 Printf 风格函数命名

声明 `Printf`-style 函数时，请确保 `go vet` 工具可以检测它并检查格式字符串。

这意味着应可能使用预定义的 `Printf`-style 函数名称。`go vet` 将默认检查这些。关于格式化的更多信息，请参见 [Printf 系列]。

  [Printf 系列]: https://golang.org/cmd/vet/#hdr-Printf_family

如果不能使用预定义的 `Printf`-style 函数名称，请以 `f` 结尾：`Wrapf` 而非 `Wrap`。因为 `go vet`可以指定检查特定的 `Printf`-style 名称，但名称必须以 `f` 结尾。

```sh
go vet -printfuncs=wrapf,statusf
```

另见 [go vet: Printf family check].

  [go vet: Printf family check]: https://kuzminva.wordpress.com/2017/11/07/go-vet-printf-family-check/

## 编程模式

### 表驱动测试

当核心测试逻辑重复时，将表驱动测试与[子测试]一起使用，以避免重复代码。

  [子测试]: https://blog.golang.org/subtests

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// func TestSplitHostPort(t *testing.T)

host, port, err := net.SplitHostPort("192.0.2.0:8000")
require.NoError(t, err)
assert.Equal(t, "192.0.2.0", host)
assert.Equal(t, "8000", port)

host, port, err = net.SplitHostPort("192.0.2.0:http")
require.NoError(t, err)
assert.Equal(t, "192.0.2.0", host)
assert.Equal(t, "http", port)

host, port, err = net.SplitHostPort(":8000")
require.NoError(t, err)
assert.Equal(t, "", host)
assert.Equal(t, "8000", port)

host, port, err = net.SplitHostPort("1:8")
require.NoError(t, err)
assert.Equal(t, "1", host)
assert.Equal(t, "8", port)
```

</td><td>

```go
// func TestSplitHostPort(t *testing.T)

tests := []struct{
  give     string
  wantHost string
  wantPort string
}{
  {
    give:     "192.0.2.0:8000",
    wantHost: "192.0.2.0",
    wantPort: "8000",
  },
  {
    give:     "192.0.2.0:http",
    wantHost: "192.0.2.0",
    wantPort: "http",
  },
  {
    give:     ":8000",
    wantHost: "",
    wantPort: "8000",
  },
  {
    give:     "1:8",
    wantHost: "1",
    wantPort: "8",
  },
}

for _, tt := range tests {
  t.Run(tt.give, func(t *testing.T) {
    host, port, err := net.SplitHostPort(tt.give)
    require.NoError(t, err)
    assert.Equal(t, tt.wantHost, host)
    assert.Equal(t, tt.wantPort, port)
  })
}
```

</td></tr>
</tbody></table>

测试表使得向错误消息注入上下文信息，减少重复逻辑，添加新的测试用例变得更加容易。

我们遵循这样的约定：将结构体切片称为 `tests`。 每个测试用例称为 `tt`。此外，我们鼓励使用 `give` 和 `want` 前缀说明每个测试用例的输入和输出值。

```go
tests := []struct{
  give     string
  wantHost string
  wantPort string
}{
  // ...
}

for _, tt := range tests {
  // ...
}
```

### 功能选项

功能选项是一种模式，声明一个不透明 Option 类型，该类型记录某些内部结构体的信息。你的函数接受这些不定数量的选项参数，并将选项参数上的全部信息作用于内部结构上。

将此模式可用于扩展构造函数和其他公共 API 中的可选参数，特别是这些参数已经有三个或者超过三个的情况下。

<table>
<thead><tr><th>Bad</th><th>Good</th></tr></thead>
<tbody>
<tr><td>

```go
// package db

func Open(
  addr string,
  cache bool,
  logger *zap.Logger
) (*Connection, error) {
  // ...
}
```

</td><td>

```go
// package db

type Option interface {
  // ...
}

func WithCache(c bool) Option {
  // ...
}

func WithLogger(log *zap.Logger) Option {
  // ...
}

// Open creates a connection.
func Open(
  addr string,
  opts ...Option,
) (*Connection, error) {
  // ...
}
```

</td></tr>
<tr><td>

必须始终提供缓存和记录器参数，即使用户希望使用默认值。

```go
db.Open(addr, db.DefaultCache, zap.NewNop())
db.Open(addr, db.DefaultCache, log)
db.Open(addr, false /* cache */, zap.NewNop())
db.Open(addr, false /* cache */, log)
```

</td><td>

只有在需要时才提供选项。

```go
db.Open(addr)
db.Open(addr, db.WithLogger(log))
db.Open(addr, db.WithCache(false))
db.Open(
  addr,
  db.WithCache(false),
  db.WithLogger(log),
)
```

</td></tr>
</tbody></table>

Our suggested way of implementing this pattern is with an `Option` interface
that holds an unexported method, recording options on an unexported `options`
struct.

建议实现此模式的方法是使用一个 `Option` 接口，该接口拥有一个未导出的方法，记录一个未导出的 `options` 结构上的选项。

```go
type options struct {
  cache  bool
  logger *zap.Logger
}

type Option interface {
  apply(*options)
}

type cacheOption bool

func (c cacheOption) apply(opts *options) {
  opts.cache = bool(c)
}

func WithCache(c bool) Option {
  return cacheOption(c)
}

type loggerOption struct {
  Log *zap.Logger
}

func (l loggerOption) apply(opts *options) {
  opts.Logger = l.Log
}

func WithLogger(log *zap.Logger) Option {
  return loggerOption{Log: log}
}

// Open creates a connection.
func Open(
  addr string,
  opts ...Option,
) (*Connection, error) {
  options := options{
    cache:  defaultCache,
    logger: zap.NewNop(),
  }

  for _, o := range opts {
    o.apply(&options)
  }

  // ...
}
```

注意: 还有一种使用闭包实现这个模式的方法，但是我们相信上面的模式为作者提供了更多的灵活性，并且用户更容易调试和测试。特别是，它允许在测试和模拟中对选项进行比较，但是闭包中是不可能的。此外，它还允许选项实现其他接口，包括 `fmt.Stringer`(支持选项的用户可读字符串表示)。

另见：

- [Self-referential functions and the design of options]
- [Functional options for friendly APIs]

  [Self-referential functions and the design of options]: https://commandcenter.blogspot.com/2014/01/self-referential-functions-and-design.html
  [Functional options for friendly APIs]: https://dave.cheney.net/2014/10/17/functional-options-for-friendly-apis
