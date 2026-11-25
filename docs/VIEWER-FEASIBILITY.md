# Biomolecular Structure Viewer MCP — 改造与接入记录

日期：2026-11-25
来源：`<MCP_DIR>`（从 Antigravity 插件 structural-biology 抽出的 sidecar）

## 组成

| 文件 | 作用 |
|---|---|
| `dist/mcp_entry.cjs` (30 KB) | stdio MCP server，无第三方依赖（只用 node: 内置模块），暴露 11 个工具 |
| `dist/server.cjs` (69 KB) | sidecar HTTP 宿主：托管 `ui.html` + `/biomolecular/*` API |
| `ui.html` + `dist/main.js` (184 KB) | Mol* 的 3D 交互面板前端 |
| `mcp_config.json` / `sidecar.json` | Antigravity 的注册清单（command: agy-node / node） |

## 已验证可用的部分

用 `node dist/mcp_entry.cjs` 直接做 JSON-RPC 握手：

```
initialize → serverInfo: science-sidecar-mcp 1.0.0, capabilities.tools
tools/list → get_state, load_structure, highlight_region, annotate_region,
             set_representation, set_overlays, clear_highlights, clear_annotations, ...
```

协议层完全标准（2024-11-05），DSH 的 `@deepseek-ai/dsh-mcp-client` 能直接对接。

## 阻碍（Antigravity 宿主耦合）

1. **工具调用强制要求 Antigravity 会话 ID**
   `mcp_entry.cjs` 末尾硬编码 `conversationScoped: true`：
   ```js
   ve({ sidecarName: "biomolecular_structure_viewer", conversationScoped: !0, tools: Ve() })
   ```
   调用任何工具时读取 `arguments.conversationId` 或 `_meta["antigravity.google/conversation_id"]`，
   然后到 brainDir 下找该会话目录；找不到就报
   `Missing or unknown conversationId (...): cannot execute MCP tool without an owning conversation.`
   实测：即使手工传 `conversationId` 也会因"会话不存在"被拒。

2. **3D 面板依赖 Antigravity sidecar 宿主**
   `server.cjs` 读取 `ANTIGRAVITY_SIDECAR_WEB_PORT/TOKEN`、`ANTIGRAVITY_APP_DATA_DIR`、
   `ANTIGRAVITY_CONVERSATION_ID` 等，由 Antigravity 主进程注入；单独启动无输出、不监听。
   DSH 没有 sidecar 面板概念，无法直接挂载。

3. **结构文件必须落在 Antigravity 会话的 artifact 目录**，工具不接受工作区路径/URL。

## DSH 侧能力（确认存在）

- 原生插件 `@deepseek-ai/dsh-mcp-client` v0.2.2-rc.5 随 app 分发。
- 配置写在 profile 的 `cordis.patch.yml`（本机：`~/.dsh/profiles/web/cordis.patch.yml`）：

```yaml
- id: mcp-structure-viewer
  name: "@deepseek-ai/dsh-mcp-client"
  config:
    serverName: structure_viewer
    transport: stdio
    command: node
    args: ["<PROJECT>\\.dsh\\mcp\\biomolecular_structure_viewer\\dist\\mcp_entry.cjs"]
    env:
      ANTIGRAVITY_APP_DATA_DIR: "<PROJECT>\\.dsh\\verify\\bio"
```

- 工具会以 `mcp__structure_viewer__load_structure` 形式出现；改配置需重启 dsh web（或触发配置热重载）。

## 三种接入方案

| 方案 | 内容 | 工作量 | 效果 |
|---|---|---|---|
| A | 打补丁 `conversationScoped:false` + 固定 state 目录，只接 MCP 工具 | 小（1 行 + 重启） | 能在 DSH 里调用工具，但无 3D 画面，工具只是写 state.json，价值有限 |
| B | A + 轻量本地宿主：静态托管 `ui.html`，把 state 读取改成本地文件；用 `sidebar_open` 打开 `http://127.0.0.1:PORT/` | 中 | 有可交互 3D 视图，但不与 DSH 会话联动 |
| C | 写成 DSH 客户端插件：注册 sidebar pane + 调用 MCP 工具 | 大 | 体验等同 Antigravity，长期方案 |

**建议 B**：改动集中在 `mcp_entry.cjs` 的 1 行 + 一个 ~100 行的本地静态/代理宿主，可保留 Mol* 全部交互。

## 备注

- `server.cjs` 里的 `/biomolecular/list-workspace-pdbs`、`/biomolecular/upload-file` 等接口绑定了 Antigravity 的 brain 目录，方案 B 需要替换为本地目录。
- 该 MCP 服务器无鉴权、无网络访问，纯本地文件读写，接入风险低。
---

# 实施记录（方案 B，2026-11-25）

## 已改动

| 文件 | 改动 |
|---|---|
| `biomolecular_structure_viewer/dist/mcp_entry.cjs` | `conversationScoped:!0` → `!1`，并注入 `resolveDataDir`；目录可用环境变量 `BIOMOLECULAR_VIEWER_DATA_DIR` 覆盖。原文件备份为 `mcp_entry.cjs.orig` |
| `~/.dsh/cordis.patch.yml`（home 级，对所有 profile 生效） | 新增 `mcp-structure-viewer` 条目（dsh-mcp-client, stdio, node） |
| `.dsh/verify/biomolecular-mcp/start-viewer.ps1` | 启动本地 sidecar 宿主（端口 7793） |

## 运行方式

1. 启动宿主（保持运行）：
   ```powershell
   powershell -ExecutionPolicy Bypass -File <PROJECT>\.dsh\verify\biomolecular-mcp\start-viewer.ps1
   ```
2. 浏览器打开：`http://127.0.0.1:7793/?conversationId=dsh`
3. 重启 dsh 后，模型侧工具为 `mcp__structure_viewer__<tool>`（load_structure / highlight_region / annotate_region / set_representation / set_overlays / clear_* / get_state）。

## 已验证

- 状态目录：`<APP_DATA_DIR>/brain/dsh/scratch/sidecars/structural-biology/biomolecular_structure_viewer/state.json`
- `GET /api/state?conversationId=dsh` 返回 MCP 写入的状态 ✅
- `GET /biomolecular/workspace-file?conversationId=dsh&path=1crn.pdb` 返回 49 KB PDB ✅
- Mol* 在浏览器中渲染 1CRN（cartoon，绿色）✅
- 工具链：MCP `load_structure` → state.json → SSE → UI 自动刷新 ✅

## 限制

- 面板是独立网页，不是 DSH 原生侧边栏；需要宿主进程常驻（脚本可放计划任务）。
- `conversationId` 固定为 `dsh`，所有会话共用一个视图状态。
- 结构文件需放在 `APP_DATA_DIR/brain/dsh/`（工具以 workspace 源相对该目录解析）。
- UI 依赖 CDN（jsdelivr / Google Fonts）加载 Mol*，离线环境会白屏。
