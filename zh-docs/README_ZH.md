# Claude Code 项目管理

[![Automaze](https://img.shields.io/badge/由-automaze.io-4b3baf)](https://automaze.io)
&nbsp;
[![Claude Code](https://img.shields.io/badge/+-Claude%20Code-d97757)](https://github.com/automazeio/ccpm/blob/main/README.md)
[![GitHub Issues](https://img.shields.io/badge/+-GitHub%20Issues-1f2328)](https://github.com/automazeio/ccpm)
&nbsp;
[![MIT License](https://img.shields.io/badge/许可证-MIT-28a745)](https://github.com/automazeio/ccpm/blob/main/LICENSE)
&nbsp;
[![在𝕏上关注](https://img.shields.io/badge/𝕏-@aroussi-1c9bf0)](http://x.com/intent/follow?screen_name=aroussi)
&nbsp;
[![给这个仓库点赞](https://img.shields.io/badge/★-给这个仓库点赞-e7b10b)](https://github.com/automazeio/ccpm)

### 使用规范驱动开发、GitHub issues、Git worktrees和并行运行的多个AI代理来交付~~更快~~_更好的_ Claude Code工作流程。

停止丢失上下文。停止在任务上阻塞。停止交付bug。这个经过实战检验的系统将PRD转化为史诗任务，将史诗任务分解为GitHub issues，并将issues转化为生产代码——每一步都有完整的可追溯性。

![Claude Code PM](screenshot.webp)

## 目录

- [背景](#背景)
- [工作流程](#工作流程)
- [与众不同之处](#与众不同之处)
- [为什么选择GitHub Issues？](#为什么选择github-issues)
- [核心原则：拒绝凭感觉编码](#核心原则拒绝凭感觉编码)
- [系统架构](#系统架构)
- [工作流程阶段](#工作流程阶段)
- [命令参考](#命令参考)
- [并行执行系统](#并行执行系统)
- [主要功能和优势](#主要功能和优势)
- [已验证的结果](#已验证的结果)
- [示例流程](#示例流程)
- [立即开始](#立即开始)
- [本地 vs 远程](#本地-vs-远程)
- [技术说明](#技术说明)
- [支持这个项目](#支持这个项目)

## 背景

每个团队都面临同样的问题：
- **会话之间上下文丢失**，迫使不断重新发现
- **并行工作在多个开发者接触相同代码时产生冲突**
- **需求偏离**，口头决定覆盖书面规范
- **进度在最后之前不可见**

这个系统解决了所有这些问题。

## 工作流程

```mermaid
graph LR
    A[PRD创建] --> B[史诗任务规划]
    B --> C[任务分解]
    C --> D[GitHub同步]
    D --> E[并行执行]
```

### 实际操作演示（60秒）

```bash
# 通过引导式头脑风暴创建全面的PRD
/ccpm:prd-new memory-system

# 将PRD转化为技术史诗任务并进行任务分解
/ccpm:prd-parse memory-system

# 推送到GitHub并开始并行执行
/ccpm:epic-oneshot memory-system
/ccpm:issue-start 1235
```

## 与众不同之处

| 传统开发             | Claude Code PM系统                 |
| -------------------- | ---------------------------------- |
| 会话之间丢失上下文   | **跨所有工作的持久上下文**         |
| 串行任务执行         | **并行代理处理独立任务**           |
| 从记忆中"凭感觉编码" | **规范驱动，全程可追溯**           |
| 进度隐藏在分支中     | **GitHub中的透明审计轨迹**         |
| 手动任务协调         | **智能优先级排序，使用`/ccpm:next`** |

## 为什么选择GitHub Issues？

大多数Claude Code工作流程在孤立环境中运行——单个开发者在本地环境中与AI协作。这产生了一个根本问题：**AI辅助开发变成了孤岛**。

通过使用GitHub Issues作为我们的数据库，我们解锁了强大的功能：

### 🤝 **真正的团队协作**
- 多个Claude实例可以同时处理同一项目
- 人类开发者通过issue评论实时查看AI进度
- 团队成员可以随时加入——上下文始终可见
- 管理者获得透明度而无需中断流程

### 🔄 **无缝的人机交接**
- AI可以开始任务，人类可以完成任务（反之亦然）
- 进度更新对每个人可见，不会困在聊天记录中
- 代码审查通过PR评论自然发生
- 无需召开"AI做了什么？"会议

### 📈 **超越个人工作的可扩展性**
- 添加团队成员无需繁琐的入职流程
- 多个AI代理并行处理不同issues
- 分布式团队自动保持同步
- 与现有的GitHub工作流程和工具兼容

### 🎯 **单一真相来源**
- 无需单独的数据库或项目管理工具
- Issue状态即项目状态
- 评论即审计轨迹
- 标签提供组织结构

这不仅仅是一个项目管理系统——它是一个**协作协议**，让人类和AI代理能够大规模协作，使用团队已经信任的基础设施。

## 核心原则：拒绝凭感觉编码

> **每一行代码都必须可追溯到规范。**

我们遵循严格的5阶段纪律：

1. **🧠 头脑风暴** - 深入思考
2. **📝 文档化** - 编写不留任何解释空间的规范
3. **📐 规划** - 通过明确的技术决策进行架构设计
4. **⚡ 执行** - 精确构建规范中指定的内容
5. **📊 跟踪** - 在每一步保持透明进度

不走捷径。不做假设。不留遗憾。

## 系统架构

CCPM作为Claude **插件**安装。运行`/ccpm:init`后，以下目录会在你的项目中创建：

```
<your-project>/
├── .claude/
│   └── rules/            # CCPM规则（从插件复制）
└── .pm/                  # PM工作区（放入.gitignore中）
    ├── epics/
    │   └── [epic-name]/  # 史诗任务和相关任务
    │       ├── epic.md
    │       ├── [#].md    # 单个任务文件
    │       └── updates/  # 进行中的更新
    └── prds/             # PRD文件
```

插件本身（命令、代理、脚本）存储在自己的仓库中，由Claude Code的插件系统加载。

## 工作流程阶段

### 1. 产品规划阶段

```bash
/ccpm:prd-new feature-name
```
启动全面的头脑风暴，创建产品需求文档，捕捉愿景、用户故事、成功标准和约束条件。

**输出：** `.pm/prds/feature-name.md`

### 2. 实现规划阶段

```bash
/ccpm:prd-parse feature-name
```
将PRD转化为技术实现计划，包含架构决策、技术方法和依赖映射。

**输出：** `.pm/epics/feature-name/epic.md`

### 3. 任务分解阶段

```bash
/ccpm:epic-decompose feature-name
```
将史诗任务分解为具体的、可操作的任务，包含验收标准、工作量估算和并行化标志。

**输出：** `.pm/epics/feature-name/[task].md`

### 4. GitHub同步

```bash
/ccpm:epic-sync feature-name
# 或对于自信的工作流程：
/ccpm:epic-oneshot feature-name
```
将史诗任务和任务作为issues推送到GitHub，带有适当的标签和关系。

### 5. 执行阶段

```bash
/ccpm:issue-start 1234  # 启动专门代理
/ccpm:issue-sync 1234   # 推送进度更新
/ccpm:next             # 获取下一个优先任务
```
专门代理实现任务，同时保持进度更新和审计轨迹。

## 命令参考

> [!TIP]
> 输入`/ccpm:help`获取简洁的命令摘要

### 初始设置
- `/ccpm:init` - 安装依赖并配置GitHub

### PRD命令
- `/ccpm:prd-new` - 为新产品需求启动头脑风暴
- `/ccpm:prd-parse` - 将PRD转换为实现史诗任务
- `/ccpm:prd-list` - 列出所有PRD
- `/ccpm:prd-edit` - 编辑现有PRD
- `/ccpm:prd-status` - 显示PRD实现状态

### 史诗任务命令
- `/ccpm:epic-decompose` - 将史诗任务分解为任务文件
- `/ccpm:epic-sync` - 将史诗任务和任务推送到GitHub
- `/ccpm:epic-oneshot` - 一次性分解和同步命令
- `/ccpm:epic-list` - 列出所有史诗任务
- `/ccpm:epic-show` - 显示史诗任务及其任务
- `/ccpm:epic-close` - 标记史诗任务为完成
- `/ccpm:epic-edit` - 编辑史诗任务详情
- `/ccpm:epic-refresh` - 从任务更新史诗任务进度

### Issue命令
- `/ccpm:issue-show` - 显示issue和子issues
- `/ccpm:issue-status` - 检查issue状态
- `/ccpm:issue-start` - 开始工作并启动专门代理
- `/ccpm:issue-sync` - 将更新推送到GitHub
- `/ccpm:issue-close` - 标记issue为完成
- `/ccpm:issue-reopen` - 重新打开已关闭的issue
- `/ccpm:issue-edit` - 编辑issue详情

### 工作流程命令
- `/ccpm:next` - 显示下一个优先issue及史诗任务上下文
- `/ccpm:status` - 整体项目仪表板
- `/ccpm:standup` - 每日站会报告
- `/ccpm:blocked` - 显示被阻塞的任务
- `/ccpm:in-progress` - 列出进行中的工作

### 同步命令
- `/ccpm:sync` - 与GitHub的双向同步
- `/ccpm:import` - 导入现有的GitHub issues

### 维护命令
- `/ccpm:validate` - 检查系统完整性
- `/ccpm:clean` - 归档已完成的工作
- `/ccpm:search` - 搜索所有内容

## 并行执行系统

### Issues并非原子性的

传统思维：一个issue = 一个开发者 = 一个任务

**现实：一个issue = 多个并行工作流**

单个"实现用户认证"issue不是一个任务。它是...

- **代理1**：数据库表和迁移
- **代理2**：服务层和业务逻辑
- **代理3**：API端点和中间件
- **代理4**：UI组件和表单
- **代理5**：测试套件和文档

所有这些都在同一工作树中**同时**运行。

### 速度的数学计算

**传统方法：**
- 包含3个issues的史诗任务
- 串行执行

**本系统：**
- 同样的史诗任务包含3个issues
- 每个issue分解为约4个并行流
- **12个代理同时工作**

我们不是将代理分配给issues。我们是**利用多个代理**来更快交付。

### 上下文优化

**传统的单线程方法：**
- 主对话承载所有实现细节
- 上下文窗口填满了数据库模式、API代码、UI组件
- 最终达到上下文限制并失去连贯性

**并行代理方法：**
- 主线程保持干净和战略性
- 每个代理独立处理自己的上下文
- 实现细节从不污染主对话
- 主线程保持监督而不会淹没在代码中

你的主对话成为指挥家，而不是管弦乐队。

### GitHub vs 本地：完美分离

**GitHub看到的内容：**
- 干净、简单的issues
- 进度更新
- 完成状态

**本地实际发生的事情：**
- Issue #1234分解为5个并行代理
- 代理通过Git提交进行协调
- 复杂的编排对视图隐藏

GitHub无需知道工作是如何完成的——只需知道工作已完成。

### 命令流程

```bash
# 分析可以并行化的内容
/ccpm:issue-analyze 1234

# 启动集群
/ccpm:epic-start multi-agent-collaboration

# 观看奇迹发生
# 12个代理在3个issues上工作
# 全部在：../epic-memory-system/中

# 完成时进行一次干净的合并
/ccpm:epic-merge memory-system
```

## 主要功能和优势

### 🧠 **上下文保存**
永不丢失项目状态。每个史诗任务维护自己的上下文，代理从`.claude/context/`读取，并在同步前本地更新。

### ⚡ **并行执行**
通过多个代理同时工作来更快交付。标记为`parallel: true`的任务支持无冲突的并发开发。

### 🔗 **GitHub原生**
与团队已使用的工具兼容。Issues是真相来源，评论提供历史，不依赖Projects API。

### 🤖 **代理专业化**
每项工作都有合适的工具。不同的代理处理UI、API和数据库工作。每个代理自动读取需求并发布更新。

### 📊 **全程可追溯**
每个决策都有文档记录。PRD → 史诗任务 → 任务 → Issue → 代码 → 提交。从想法到生产的完整审计轨迹。

### 🚀 **开发者生产力**
专注于构建，而非管理。智能优先级排序，自动上下文加载，准备就绪时增量同步。

## 已验证的结果

使用此系统的团队报告：
- **89%的时间**不再因上下文切换而丢失——你将很少使用`/compact`和`/clear`
- **5-8个并行任务** vs 之前的1个——同时编辑/测试多个文件
- **bug率降低75%**——由于将功能分解为详细任务
- **功能交付速度提升3倍**——基于功能大小和复杂度

## 示例流程

```bash
# 开始新功能
/ccpm:prd-new memory-system

# 审查和完善PRD...

# 创建实现计划
/ccpm:prd-parse memory-system

# 审查史诗任务...

# 分解为任务并推送到GitHub
/ccpm:epic-oneshot memory-system
# 创建issues：#1234（史诗任务），#1235，#1236（任务）

# 开始任务开发
/ccpm:issue-start 1235
# 代理开始工作，在本地维护进度

# 同步进度到GitHub
/ccpm:issue-sync 1235
# 更新作为issue评论发布

# 检查整体状态
/ccpm:epic-show multi-agent-collaboration
```

## 立即开始

### 快速设置（2分钟）

1. **在Claude Code中添加CCPM marketplace并安装插件**：

   ```
   /plugin marketplace add rknuus/ccpm
   /plugin install ccpm@ccpm-marketplace
   ```

   **或本地测试而不安装**（例如测试fork或分支）：

   ```bash
   # 从你的项目目录，指向本地克隆
   claude --plugin-dir /path/to/ccpm
   ```

   这仅为当前会话加载插件。命令在相同的 `/ccpm:*` 命名空间下可用。

2. **初始化PM系统**：
   ```bash
   /ccpm:init
   ```
   此命令将：
   - 安装GitHub CLI（如需要）
   - 与GitHub进行身份验证
   - 安装[gh-sub-issue扩展](https://github.com/yahsan2/gh-sub-issue)以建立正确的父子关系
   - 创建所需目录
   - 更新.gitignore

3. **创建包含仓库信息的`CLAUDE.md`**
   ```bash
   /init include rules from .claude/CLAUDE.md
   ```
   > 如果你已有`CLAUDE.md`文件，运行：`/re-init`来用`.claude/CLAUDE.md`中的重要规则更新它。

4. **准备系统**：
   ```bash
   /context:create
   ```



### 开始你的第一个功能

```bash
/ccpm:prd-new your-feature-name
```

观看结构化规划如何转化为交付的代码。

## 本地 vs 远程

| 操作       | 本地 | GitHub    |
| ---------- | ---- | --------- |
| PRD创建    | ✅    | —         |
| 实现规划   | ✅    | —         |
| 任务分解   | ✅    | ✅（同步） |
| 执行       | ✅    | —         |
| 状态更新   | ✅    | ✅（同步） |
| 最终交付物 | —    | ✅         |

## 技术说明

### GitHub集成
- 使用**gh-sub-issue扩展**建立正确的父子关系
- 如果未安装扩展则回退到任务列表
- 史诗任务issues自动跟踪子任务完成情况
- 标签提供额外组织（`epic:feature`，`task:feature`）

### 文件命名约定
- 任务在分解期间以`001.md`，`002.md`开始
- GitHub同步后，重命名为`{issue-id}.md`（例如，`1234.md`）
- 便于导航：issue #1234 = 文件`1234.md`

### 设计决策
- 故意避免GitHub Projects API的复杂性
- 所有命令首先在本地文件上操作以提高速度
- 与GitHub的同步是明确且受控的
- Worktrees为并行工作提供干净的git隔离
- GitHub Projects可以单独添加用于可视化

---

## 支持这个项目

Claude Code PM由[Automaze](https://automaze.io)开发，**为交付产品的开发者，由交付产品的开发者**。

如果Claude Code PM帮助你的团队交付更好的软件：

- ⭐ **[给这个仓库点赞](https://github.com/automazeio/ccpm)** 来表达你的支持
- 🐦 **[在X上关注@aroussi](https://x.com/aroussi)** 获取更新和提示


---

> [!TIP]
> **使用Automaze更快交付。** 我们与创始人合作，将他们的愿景变为现实，扩展他们的业务，并优化成功。
> **[访问Automaze与我预约通话 ›](https://automaze.io)**

---

## 点赞历史

![点赞历史图表](https://api.star-history.com/svg?repos=automazeio/ccpm)
