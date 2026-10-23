# pi-builds

基于 [Pi Coding Agent](https://github.com/earendil-works/pi/tree/main/packages/coding-agent) 构建可复现、可组合的 Docker 镜像，用于研究不同 Agent 组件对 Coding 任务的实际增益。

> **当前状态：规划阶段。** 仓库目前只有一个空的根目录 `Dockerfile`；下文的目录、镜像变体和构建命令是目标设计，尚未全部实现。

## 项目背景

Coding Agent 的最终表现不仅取决于底层 LLM，还与工具能力、任务规划、上下文管理以及多智能体协作有关。本项目计划使用**本地部署的小参数量模型**，在固定模型和评测任务的条件下，对这些组件进行独立与组合实验，回答：

- 哪些组件能够显著提高 Coding 任务完成率？
- 改善来自更准确的代码定位、更合理的执行流程，还是更有效的上下文利用？
- 性能增益是否值得额外的 Token、模型调用次数和执行时间？
- 对于不同类型的任务（Bug Fix、跨文件修改、重构等），哪些扩展更有价值？

选择 Pi 的原因是：其 Coding Agent 默认已具备完整的 ReAct + Coding Tools + Session/Compaction 能力，又通过 Extension、Skill 等机制支持增量扩展，无需重写 Agent Loop。

本仓库**只负责构建和维护 Agent 运行环境镜像**，不负责实现 Benchmark Case 或通用评测调度。后续计划与 [Harbor](https://github.com/laude-institute/harbor) 等容器化评测工具集成。

## 设计原则

1. **保留原生 Baseline。** 首先完整保留 Pi Coding Agent 的默认功能，不为了追求“最简”而删除 Compaction、Session、重试等现有机制。
2. **扩展可独立比较。** 每种镜像变体在同一 Baseline 上增加一类能力；复杂插件如同时提供 Tool、Prompt、Skill，需记录实际启用的资源。
3. **固定环境与版本。** 固定 Pi、插件、语言服务、运行时及系统依赖版本；尽量复用共同基础镜像。
4. **在容器层控制能力。** 不能仅靠 Pi 的 Tool 配置禁用某个组件：模型拥有 Bash 权限，可能执行程序、修改配置或自行安装插件。实验镜像应尽量只包含当前实验允许的能力。
5. **兼容无人值守评测。** 扩展应优先支持非交互运行，避免依赖 TUI 人工确认；镜像内不预置密钥。

## 预期目录结构

以下为**规划结构**，并非当前仓库已存在的文件：

~~~text
pi-builds/
├── README.md
├── Dockerfile                       # 当前空占位文件，后续整理
├── docker/
│   ├── base/
│   │   └── Dockerfile               # Node.js、Pi、通用 CLI 依赖
│   ├── baseline/
│   │   └── Dockerfile               # 原生 Pi Coding Agent
│   └── extensions/
│       ├── lsp/
│       │   └── Dockerfile
│       ├── ast-search/
│       │   └── Dockerfile
│       ├── plan-todo/
│       │   └── Dockerfile
│       ├── subagent/
│       │   └── Dockerfile
│       ├── skills/
│       │   └── Dockerfile
│       └── context-management/
│           └── Dockerfile
├── configs/                          # 每种镜像的 Pi 配置
│   ├── baseline/
│   └── extensions/
├── skills/                           # 实验使用的 Skill 内容
├── scripts/                          # 构建与 Smoke Test 脚本
└── manifests/                        # 镜像变体及版本清单
~~~

目录只表示实验维度，不要求每种能力永久对应唯一实现。例如 LSP 可以根据语言服务或具体 Extension 拆分子变体；Plan 与 Todo 也可以在后续分别构建，以避免混淆两种机制的增益。

## Agent Baseline

**Baseline = 原生 Pi Coding Agent（不额外安装第三方能力插件）。**

计划通过 npm 安装版本固定的 `@earendil-works/pi-coding-agent`，并保留其原有默认行为：

| 能力 | Baseline |
| --- | --- |
| Agent Runtime | Pi 原生 ReAct / Tool Calling / 事件循环 |
| 模型接入 | Pi 支持的 Provider，评测时固定到同一个本地模型 |
| Coding Tools | 默认 `read`、`bash`、`edit`、`write` |
| System Prompt | Pi 默认 Coding Prompt |
| Context | Pi 默认上下文构建与自动 Compaction |
| Session | Pi 原生 Session、上下文记录及相关机制 |
| 可靠性机制 | 保留 Pi 默认重试等行为 |
| 扩展能力 | 保留内置扩展框架及其原生默认行为，不额外引入第三方工具 |
| 执行接口 | 优先使用 RPC / SDK 接入评测器；交互式 CLI 可用于调试 |

注意：**“保留全部默认功能”并不等于预装所有社区插件。** Baseline 中仍然存在 Pi 自带的 Extension、Skill、MCP 等加载机制，但不主动提供新的第三方插件及服务。Pi 原生的 `codemode`、`tool_search` 等内置工具也遵循其默认激活状态。

如果 Benchmark 仓库本身带有 `AGENTS.md` 等项目指令，Pi 可能自动读取。后续实验应保证各组获得相同的项目上下文，并在实验记录中标明。

## 计划评测的扩展方向

以下均为**候选方向**，并不表示对应 Dockerfile、第三方插件或实验结果已完成。

| 方向 | 拟增加的能力 | 主要研究问题 | 可参考的实现 |
| --- | --- | --- | --- |
| **LSP** | 定义跳转、引用查找、符号索引、类型/诊断信息 | 能否减少跨文件定位成本，提高语义修改准确率？ | Pi 社区 LSP 扩展 + `gopls` / `pyright` / TypeScript Language Server |
| **AST Search** | 基于语法树的结构化搜索、代码 Outline；可进一步测试 AST Rewrite | 与 `rg` + `read` 相比，是否能更准确定位代码结构并减少上下文开销？ | `ast-grep` 及相应 Pi Extension |
| **Plan / Todo** | 显式任务清单、步骤跟踪、先规划后执行的工作流 | 是否减少复杂任务遗漏？强制 Plan 与可选 Todo 哪种更有效？ | [Pi Plan Mode 示例](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/plan-mode)、[Todo 示例](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/todo.ts) |
| **Subagent** | 独立上下文的任务委派；可测试探索、实现、审查及并行执行 | 隔离上下文与多 Agent 协作是否提升任务成功率，代价是多少？ | [Pi Subagent 示例](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent) |
| **Skill** | 面向特定语言、工具或工作流的按需指导与配套资源 | 专门指令能否弥补小模型的工程经验不足？ | Pi 原生 [Skills](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md) |
| **Context Management** | 在原生 Compaction 之上探索更好的摘要、关键上下文保留或检索策略 | 长任务能否减少信息丢失及重复探索，同时控制 Token 成本？ | [Pi 自定义 Compaction 示例](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/custom-compaction.ts) |

初步建议先对 **LSP、AST Search、Plan/Todo、Subagent、Skill** 做单组件实验，再考虑更复杂的组合。Context Management 需要与 Pi 已有的自动 Compaction 比较，而不是与“完全没有压缩”比较。

尤其需要区分：

- **AST Search 与 AST Rewrite**：前者改变信息检索能力，后者还改变代码修改能力。
- **Todo 与 Plan Mode**：前者提供任务状态工具，后者可能改变整个执行流程。
- **Subagent Tool 与固定多 Agent 工作流**：前者由主模型决定是否委派，后者由外部工作流规定执行步骤。
- **Skill 内容与 Prompt Engineering**：Skill 本质包含指令信息，需记录其加载时机、可见内容与额外 Token。

## 镜像构建与使用（规划）

基础镜像计划使用 Node.js 运行时，通过 npm 直接安装 Pi，无须从 Monorepo 编译：

~~~dockerfile
FROM node:24-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash git ripgrep ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 正式实现时固定到经过验证的确切版本
ARG PI_VERSION
RUN test -n "$PI_VERSION" && \
    npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}"

WORKDIR /workspace
ENTRYPOINT ["pi"]
~~~

各扩展镜像在共同基础镜像之上安装对应插件及其运行依赖，不在任务执行时在线安装。构建时固定插件版本；必要时以只读方式提供配置和插件目录。

待目录与 Dockerfile 落地后，预期使用类似命令构建（**当前不可直接执行**）：

~~~bash
docker build -f docker/base/Dockerfile -t pi-builds:base .
docker build -f docker/baseline/Dockerfile -t pi-builds:baseline .
docker build -f docker/extensions/lsp/Dockerfile -t pi-builds:lsp .
~~~

镜像应支持非交互启动，如 `pi --mode rpc --no-session`。具体如何与 Harbor 的 Agent/Task 执行协议对接，将在后续实现；**Agent 容器与 Case 容器的文件系统和进程环境不能因为共享工作目录就被视为完全相同**。

## 实验与可复现性约定

正式评测时尽量固定模型权重/量化、推理配置、Benchmark Case、超时及任务资源限制。建议至少记录任务成功率、端到端耗时、输入/输出 Token、模型调用次数、Tool 调用次数，以及子 Agent 和 Compaction 的额外开销。

每个镜像变体应记录 Pi 版本、插件来源及 Commit/版本、系统依赖、启用的 Tool/Skill/Prompt、镜像 Digest 和构建命令。必要时保存完整的 Agent 执行轨迹，便于分析工具是否真正被使用。

**实验隔离尤其重要：** 由于 Agent 拥有 Bash 权限，Pi 配置中的工具开关不是安全边界。应通过不同镜像、只读挂载、独立 HOME/工作区、受控网络和容器权限减少实验组之间的能力泄漏；不要向 Agent 暴露宿主 Docker Socket，也不要把模型密钥写进镜像。

## 相关项目

- [Pi Monorepo](https://github.com/earendil-works/pi)
- [Pi Coding Agent 文档](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/docs)
- [Pi Extension 示例](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions)
- [Pi Package 文档](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md)
- [Harbor](https://github.com/laude-institute/harbor)
