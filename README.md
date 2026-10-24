# pi-builds

基于 [Pi Coding Agent](https://github.com/earendil-works/pi/tree/main/packages/coding-agent) 构建可复现、可组合的 Docker 镜像，用于研究不同 Agent 组件对 Coding 任务的实际增益。

> **当前状态：Dockerfile + Makefile 初版。** 已实现 Baseline 和六类扩展镜像的 Dockerfile，可通过根目录 `Makefile` 构建；Context Management 暂缓。尚未在 CI 中完成实际 Docker build 验证。

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

## Dockerfile 目录结构

以下七个 Dockerfile 已写入仓库：

```text
pi-builds/
├── README.md
├── Makefile
└── docker/
    ├── baseline/
    │   └── Dockerfile              # Node.js + Pi Coding Agent
    └── extensions/
        ├── lsp/
        │   └── Dockerfile          # Python LSP (Pyright)
        ├── ast-search/
        │   └── Dockerfile          # AST Search / Rewrite
        ├── plan-todo/
        │   └── Dockerfile          # Todo + 可选 Plan Mode
        ├── subagent/
        │   └── Dockerfile          # 独立子 Agent
        ├── skills/
        │   └── Dockerfile          # Regression Debugging Skill
        └── web-search/
            ├── Dockerfile          # Web Search (runtime-selectable provider)
            └── web-search.json     # pi-web-access 限制配置
```

不再设置单独的通用 `base` 镜像；**Baseline 自身就是六类扩展镜像的父镜像**。`Context Management` 保留为后续评测方向，目前不创建对应 Dockerfile。

## Agent Baseline

**Baseline = 原生 Pi Coding Agent（不额外安装第三方能力插件）。**

计划通过 npm 安装版本固定的 `@earendil-works/pi-coding-agent`，并保留其原有默认行为：

| 能力          | Baseline                                               |
| ------------- | ------------------------------------------------------ |
| Agent Runtime | Pi 原生 ReAct / Tool Calling / 事件循环                |
| 模型接入      | Pi 支持的 Provider，评测时固定到同一个本地模型         |
| Coding Tools  | 默认 `read`、`bash`、`edit`、`write`                   |
| System Prompt | Pi 默认 Coding Prompt                                  |
| Context       | Pi 默认上下文构建与自动 Compaction                     |
| Session       | Pi 原生 Session、上下文记录及相关机制                  |
| 可靠性机制    | 保留 Pi 默认重试等行为                                 |
| 扩展能力      | 保留内置扩展框架及其原生默认行为，不额外引入第三方工具 |
| 执行接口      | 优先使用 RPC / SDK 接入评测器；交互式 CLI 可用于调试   |

注意：**“保留全部默认功能”并不等于预装所有社区插件。** Baseline 中仍然存在 Pi 自带的 Extension、Skill、MCP 等加载机制，但不主动提供新的第三方插件及服务。Pi 原生的 `codemode`、`tool_search` 等内置工具也遵循其默认激活状态。

如果 Benchmark 仓库本身带有 `AGENTS.md` 等项目指令，Pi 可能自动读取。后续实验应保证各组获得相同的项目上下文，并在实验记录中标明。

## 计划评测的扩展方向

以下均为**候选评测方向**。LSP、AST Search、Plan/Todo、Subagent、Skill、Web Search 的 Dockerfile 已实现初版，但尚未完成 Docker 构建或端到端评测；Context Management 暂缓。

| 方向                   | 拟增加的能力                                                   | 主要研究问题                                                      | 可参考的实现                                                                                                                                                                                                                           |
| ---------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **LSP（Python-only）** | 定义跳转、引用查找、符号索引、类型/诊断信息                   | 能否减少跨文件定位成本，提高语义修改准确率？                      | `pi-diet-lsp` + `pyright`（先针对 SWE-bench Verified）                                                                                                                                                                    |
| **AST Search**         | 基于语法树的结构化搜索、代码 Outline；可进一步测试 AST Rewrite | 与 `rg` + `read` 相比，是否能更准确定位代码结构并减少上下文开销？ | `ast-grep` 及相应 Pi Extension                                                                                                                                                                                                         |
| **Plan / Todo**        | 显式任务清单、步骤跟踪、先规划后执行的工作流                   | 是否减少复杂任务遗漏？强制 Plan 与可选 Todo 哪种更有效？          | [Pi Plan Mode 示例](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/plan-mode)、[Todo 示例](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/todo.ts) |
| **Subagent**           | 独立上下文的任务委派；可测试探索、实现、审查及并行执行         | 隔离上下文与多 Agent 协作是否提升任务成功率，代价是多少？         | [Pi Subagent 示例](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent)                                                                                                                  |
| **Skill**              | 面向特定语言、工具或工作流的按需指导与配套资源                 | 专门指令能否弥补小模型的工程经验不足？                            | Pi 原生 [Skills](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/skills.md)                                                                                                                                  |
| **Web Search** | 访问外部技术文档与问题资料的独立搜索工具 | 搜索结果是否提高 Coding Agent 的修复成功率？ | [pi-web-access](https://github.com/nicobailon/pi-web-access)，可配置搜索后端 |
| **Context Management** | 在原生 Compaction 之上探索更好的摘要、关键上下文保留或检索策略 | 长任务能否减少信息丢失及重复探索，同时控制 Token 成本？           | [Pi 自定义 Compaction 示例](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/custom-compaction.ts)                                                                                             |

初步建议先对 **LSP、AST Search、Plan/Todo、Subagent、Skill、Web Search** 做单组件实验，再考虑更复杂的组合。Context Management 需要与 Pi 已有的自动 Compaction 比较，而不是与“完全没有压缩”比较。

尤其需要区分：

- **AST Search 与 AST Rewrite**：前者改变信息检索能力，后者还改变代码修改能力。
- **Todo 与 Plan Mode**：前者提供任务状态工具，后者可能改变整个执行流程。
- **Subagent Tool 与固定多 Agent 工作流**：前者由主模型决定是否委派，后者由外部工作流规定执行步骤。
- **Skill 内容与 Prompt Engineering**：Skill 本质包含指令信息，需记录其加载时机、可见内容与额外 Token。

## 镜像构建与使用

在仓库根目录运行 Make 命令，所有目标均以仓库根目录作为 Docker build context：

```bash
make                 # 构建 Baseline 和六种扩展
make baseline        # 只构建 Baseline
make lsp             # 构建 Baseline + LSP
make ast-search      # 构建 Baseline + AST Search
make plan-todo       # 构建 Baseline + Plan/Todo
make subagent        # 构建 Baseline + Subagent
make skills          # 构建 Baseline + Skills
make web-search      # 构建 Baseline + Web Search
make extensions      # 构建 Baseline + 全部六种扩展
make help            # 查看可用目标和变量
```

默认的扩展目标依赖 Baseline，先构建父镜像，再构建对应扩展；Docker 会复用已缓存的镜像层。默认镜像标签为 `pi-builds:baseline`、`pi-builds:lsp`、`pi-builds:ast-search`、`pi-builds:plan-todo`、`pi-builds:subagent`、`pi-builds:skills`、`pi-builds:web-search`。

支持覆盖镜像名称、Pi 版本和 Docker 构建选项：

```bash
make all IMAGE_NAME=my-pi PI_VERSION=1.4.0
make lsp DOCKER_BUILD_ARGS="--progress=plain --no-cache"
make lsp BASE_IMAGE=custom/pi:baseline  # 外部父镜像存在时无需构建本地 Baseline
```

**Docker Hub Token 兼容性：** 当前默认 `docker` Driver 的构建环境中出现过 `docker pull` 正常、但 Buildx 客户端访问 `auth.docker.io/token` 时连接被重置的情况。已在 Makefile 默认导出 `BUILDKIT_NO_CLIENT_TOKEN=1`，使 Token 获取由 BuildKit 后端处理，因此通常可以直接执行 `make lsp` 或 `make all`。如不需要这一兼容设置，可以使用 `BUILDKIT_NO_CLIENT_TOKEN=0 make lsp` 覆盖。该配置可能改变 Registry 凭据的传递路径；使用独立远程或不可信 Builder 时，应评估认证和凭据安全性。

`DOCKER_BUILD_ARGS` 也可以向 Dockerfile 传递额外的 `--build-arg`（如 `LSP_EXTENSION_VERSION`、`PYRIGHT_VERSION`）。修改 Pi 版本时应同步确认 Plan/Todo 和 Subagent 的 `PI_SOURCE_COMMIT` 与 Pi 运行版本兼容。Skills 镜像使用 Dockerfile heredoc，需要 BuildKit。

所有扩展 Dockerfile 默认 `ARG BASE_IMAGE=pi-builds:baseline`，可通过 `--build-arg BASE_IMAGE=...` 指定另一个已构建的基线镜像。Baseline 默认固定 Pi `1.4.0`。正式实验还应固定基础镜像 Digest 并保存实际构建产生的 Digest。

| 镜像         | 已集成的内容                                                                         | 需要注意                                                                                                  |
| ------------ | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `baseline`   | Pi `@earendil-works/pi-coding-agent@1.4.0`、Git、ripgrep 等                          | 不增加第三方能力                                                                                          |
| `lsp`        | `pi-diet-lsp@0.1.9`、`pyright@1.1.413` | 仅预装 Python 语言服务器；不包含 gopls、Go Toolchain 或 TypeScript Language Server                                             |
| `ast-search` | `@juvio15/pi-ast-grep@0.4.2`、`@ast-grep/cli@0.45.3`                                 | 显式关闭该插件附带的 Skill，减少与 Skill 实验的混淆                                                       |
| `plan-todo`  | Pi `v1.4.0` 源码对应的 Todo、Plan Mode 示例                                          | **Todo 可用于无人值守任务；原版 Plan Mode 的“规划后确认执行”需要交互 UI，不能直接当作无人值守 Plan 实验** |
| `subagent`   | Pi `v1.4.0` 官方 Subagent 示例和四种 Agent 定义                                      | 删除示例里写死的 Claude 模型，子 Agent 继承主模型；不复制预设工作流 Prompt                                |
| `skills`     | 自带的 `regression-debugging` Skill                                                  | 只改变按需指导信息，不安装额外执行工具；需要支持 heredoc 的 Docker BuildKit                               |
| `web-search` | `pi-web-access@0.44.0`（只启用 `web_search`） | 搜索 Provider 由运行时配置决定；默认 `auto`，不启用 Fetch、Source Check 或交互命令 |

### Python-only LSP 镜像

`make lsp` 构建 `pi-builds:lsp`，目前只为 **SWE-bench Verified（Python）** 安装 `pyright-langserver`，使用 `pi-diet-lsp` 提供按需查询定义、引用、符号和诊断的工具。不再构建 Go 多阶段镜像，也不安装 gopls、Go Toolchain、TypeScript 或 TypeScript Language Server。

Pyright 本身通过 Node.js 运行；**Case 环境仍需提供用于构建、安装依赖和测试的 Python 工具链**，并确保 Agent 的 LSP 进程能够访问正确的源码、虚拟环境和依赖。这里限制的是本镜像预装的语言服务器；`pi-diet-lsp` 本身仍包含其他语言的内置映射，如果运行环境的 `PATH` 另有对应服务器，插件仍可能调用它们。正式实验需要固定实际执行环境以保证只有 Python LSP 可用。

```bash
make lsp
# 如需变更 Pyright 版本：
make lsp DOCKER_BUILD_ARGS="--build-arg PYRIGHT_VERSION=1.1.413"
```

### Web Search 镜像（运行时选择搜索后端）

`make web-search` 生成 `pi-builds:web-search`，基于 Baseline 安装固定版本的 [pi-web-access](https://github.com/nicobailon/pi-web-access)。默认配置为 [docker/extensions/web-search/web-search.json](docker/extensions/web-search/web-search.json)：

- `provider=auto`，不设置 `webSearch.allowedProviders`，由 pi-web-access 选择可用的搜索后端；**镜像没有锁定 DeepSeek 或其他 Provider**。
- 为控制消融实验变量，默认仅启用 `web_search`，关闭 `source_check`、`fetch_content`、`get_search_content` 和交互命令。
- `toolActivation=eager`：Agent 从第一轮即可使用搜索 Tool；`workflow=none`：不启用 Curator 或额外的搜索结果摘要模型。
- API Key 和搜索后端配置均由**容器运行时**提供，不写入镜像。

例如，无需重新构建即可选择 DeepSeek Search：

```bash
make web-search
cp docker/extensions/web-search/web-search.json /tmp/pi-web-search.json
# 编辑 /tmp/pi-web-search.json：将 "provider": "auto" 改为 "provider": "deepseek"
# 可选：设置 "webSearch": {"enabled": true, "allowedProviders": ["deepseek"]}，将运行时提供方限制为 DeepSeek

docker run --rm -it \
  -e DEEPSEEK_API_KEY \
  -v /tmp/pi-web-search.json:/root/.pi/agent/web-search.json:ro \
  -v "$PWD:/workspace" \
  pi-builds:web-search
```

使用 Brave 或 SearXNG 时，同样修改挂载文件中的 `provider`（如 `brave`、`searxng`），并配置所需的 `BRAVE_API_KEY` 或 `searxngBaseUrl`。支持的 Provider 和参数参见 [pi-web-access 文档](https://github.com/nicobailon/pi-web-access)。注意：`provider=auto` 可以触发插件自身的后端选择或回退；为保证实验结果可比较，建议每次评测明确记录或固定运行时 Provider。

Harbor 网络策略需要放行实际使用的搜索 API（例如 `api.deepseek.com` 或内部网关）。应避免检索到 Benchmark 公开答案，并记录查询与结果。**关闭独立 Fetch Tool 不是安全隔离**：`web_search` 自身仍支持 `includeContent` 参数，拥有 Bash 的 Agent 也可能自行联网。若要严格限制，必须在 Case 网络层配置出站策略。

Plan/Todo 和 Subagent 的官方示例文件固定到 Pi `v1.4.0` 的源码 Commit `4a080252f06caf63a525d7873c5d94d3c23887e0`，避免构建时随 `main` 分支漂移。下载发生在构建阶段，正常评测不需要在线安装插件。

所有镜像继承 Baseline 的 `ENTRYPOINT ["pi"]` 和 `WORKDIR /workspace`，可以在启动容器时传入 `--mode rpc --no-session` 等参数。示例：

```bash
docker run --rm -i -v "$PWD:/workspace" pi-builds:baseline --mode rpc --no-session
```

上述命令仅说明 Pi 的执行入口，并非 Harbor Agent Adapter 的完整实现。接入 Harbor 时还需要处理任务输入、停止条件和工具执行环境。**Agent 容器与 Case 容器共享工作目录，不代表它们有相同的运行时、依赖或进程视图。**

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
