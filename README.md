# DSH Science Skills Pack v1.0.0

面向 **DeepSeek Harness (DSH)** 的科研技能包：

- **50 个技能**：化学信息学、基因组、文献检索、结构生物学（源：Google Antigravity science plugins）
- **1 个 Mol\* 三维结构查看器 MCP**：已去除 Antigravity 宿主依赖，可在 DSH 中直接使用

装完之后，模型可以查 PubChem/ChEMBL/PubMed/ClinVar/PDB/UniProt 等数据库、算 RDKit 描述符、跑 PyMOL 渲染，
还能把结构丢进交互式 3D 查看器里看。

> 仓库：<https://github.com/ff66ccff/DSH-science-skills-pack>　·　许可证：[CC BY-NC 4.0](LICENSE)（署名 · 非商业）

---

## 一、前置条件

| 依赖 | 用途 | 检查 |
|---|---|---|
| DSH 桌面端 | 运行环境 | 能正常打开会话 |
| Node.js | MCP 服务器 + 查看器宿主 | `node --version` |
| uv | 大部分 Python 技能脚本用它自动装依赖 | `uv --version`（https://docs.astral.sh/uv/） |
| 网络 | 技能访问公开数据库；查看器从 jsdelivr 载入 Mol\* | 能打开网页即可 |

> 没有 uv 也能用，但需要自己 `pip install` 脚本里声明的依赖。

---

## 二、一键安装（推荐）

**方式 A：git clone（便于更新）**

```powershell
git clone https://github.com/ff66ccff/DSH-science-skills-pack.git D:\tools\DSH-science-skills-pack
```

**方式 B：下载 zip**，解压到任意位置（下例为 `D:\tools\dsh-science-skills-pack`）。

然后：

1. 打开 PowerShell，**cd 到你要使用技能的项目目录**
2. 运行：

```powershell
powershell -ExecutionPolicy Bypass -File D:\tools\dsh-science-skills-pack\scripts\install.ps1
```

安装脚本会：

| 目标 | 内容 |
|---|---|
| `<项目>\.dsh\skills\` | 50 个技能（项目级，只对当前工作区生效） |
| `<项目>\.dsh\mcp\biomolecular_structure_viewer\` | 已打补丁的 MCP 服务器 |
| `<项目>\.dsh\biomolecular-viewer\` | 查看器状态目录（结构文件放这里） |
| `%USERPROFILE%\.dsh\cordis.patch.yml` | 追加 MCP 配置（自动备份原文件） |

常用参数：

```powershell
# 装到指定项目
... install.ps1 -Project D:\my-project

# 只装技能，不配置 MCP
... install.ps1 -SkipMcp

# 只配 MCP，不动技能
... install.ps1 -SkipSkills
```

4. **完全退出并重启 DSH**（配置在启动时加载）
5. 新会话里说一句「列出结构查看器有哪些工具」验证

---

## 三、手动安装

不想跑脚本时，三步等价操作：

```powershell
# 1) 技能：复制到项目级目录
New-Item -ItemType Directory -Force '<项目>\.dsh\skills'
Copy-Item .\skills\* '<项目>\.dsh\skills\' -Recurse -Force

# 2) MCP：复制服务器
Copy-Item .\mcp\biomolecular_structure_viewer '<项目>\.dsh\mcp\biomolecular_structure_viewer' -Recurse -Force

# 3) 配置：把 config\cordis.patch.snippet.yml 的内容追加到
#    %USERPROFILE%\.dsh\cordis.patch.yml，并把 <MCP_DIR>/<PROJECT> 换成真实路径
```

---

## 四、使用三维结构查看器

1. 启动宿主（**保持窗口开着**）：

```powershell
powershell -ExecutionPolicy Bypass -File D:\tools\dsh-science-skills-pack\scripts\start-viewer.ps1
```

2. 浏览器打开：<http://127.0.0.1:7793/?conversationId=dsh>

3. 把结构文件（`.pdb` / `.cif` / `.mmcif`）放到：
   `<项目>\.dsh\biomolecular-viewer\brain\dsh\`

4. 对模型说：

   > 把 1crn.pdb 加载到结构查看器，用 cartoon 显示，并把 His12 高亮成蓝色

   模型会调用 `mcp__structure_viewer__load_structure` / `highlight_region` 等工具，页面自动刷新。

可用工具：`get_state`、`load_structure`、`highlight_region`、`annotate_region`、`set_representation`、`set_overlays`、`clear_highlights`、`clear_annotations`。

> 端口被占用时用 `start-viewer.ps1 -Port 7794`，并用新端口打开页面。

---

## 五、API Key（可选）

绝大多数技能用公开 API，**无需 key**。以下功能需要凭证，写到 `%USERPROFILE%\.env`：

| 变量 | 影响的技能 |
|---|---|
| `ALPHAGENOME_API_KEY` | alphagenome 三个技能（需在 DeepMind 页面申请免费 key） |
| `BOLTZ_API_KEY` | cheminformatics-cofolding 的 Boltz 推理 |
| `MCULE_API_KEY` / `chemspace_api_key` / `molport_api_key` | 化合物采购报价 |
| `NCBI_API_KEY` / `NCBI_EMAIL` / `USER_EMAIL` | 提升 NCBI 限额、礼貌标识（可选） |
| `OPENALEX_API_KEY` / `FDA_API_KEY` | 提升配额（可选） |

安全写法（输入不回显，也不会进对话）：

```powershell
$envFile = Join-Path $HOME ".env"
$sec = Read-Host -AsSecureString "Enter ALPHAGENOME_API_KEY (input hidden)"
$key = [System.Net.NetworkCredential]::new("", $sec).Password
$keep = if (Test-Path $envFile) { Get-Content $envFile | Where-Object { $_ -notmatch '^ALPHAGENOME_API_KEY=' } } else { @() }
($keep + "ALPHAGENOME_API_KEY=$key") | Set-Content -Path $envFile -Encoding ascii
Remove-Variable sec, key
```

---

## 六、验证清单

- [ ] 重启 DSH 后，模型工具列表里出现 `mcp__structure_viewer__get_state`
- [ ] `start-viewer.ps1` 启动后，浏览器能打开查看器页面
- [ ] 页面上传/加载 `1crn.pdb` 能看到 CRAMBIN 的 cartoon 结构
- [ ] 让模型跑一个数据库技能，例如「查 PubChem 里 aspirin 的 CID」
- [ ] 让模型跑一个本地计算技能，例如「用 RDKit 画 aspirin 的 2D 结构」

---

## 七、目录结构

```
dsh-science-skills-pack-1.0.0/
├── README.md                  # 本文件
├── MANIFEST.json              # 技能清单（名称/目录）
├── skills/                    # 50 个技能，复制到 <项目>/.dsh/skills
├── mcp/
│   └── biomolecular_structure_viewer/   # 已打补丁的 MCP + Mol* UI
├── scripts/
│   ├── install.ps1            # 一键安装
│   ├── start-viewer.ps1       # 启动 3D 查看器宿主
│   └── uninstall.ps1          # 卸载（可保留技能）
├── config/
│   └── cordis.patch.snippet.yml   # 手动配置模板
└── docs/
    ├── SKILLS-INSTALL.md      # 技能包安装/验证细节、工具名映射
    └── VIEWER-FEASIBILITY.md  # 查看器 MCP 的改造记录与原理
```

---

## 八、卸载

```powershell
# 移除 MCP 配置条目（会先备份 cordis.patch.yml）
... uninstall.ps1

# 同时删除项目里的技能与 MCP 目录
... uninstall.ps1 -RemoveFiles
```

技能是纯文件，也可以直接删 `<项目>\.dsh\skills` 下对应目录。

---

## 九、已知限制 / FAQ

**Q: 重启后看不到 MCP 工具？**
检查 `%USERPROFILE%\.dsh\cordis.patch.yml` 是否有 `mcp-structure-viewer` 条目、
`node` 是否在 PATH、以及 DSH 日志里有没有 `dsh-mcp-client` 的报错。

**Q: Alphagenome 技能报 `requires-python >=3.14`？**
这两个技能的 `pyproject.toml` 要求 3.14，而 `uv` 需要从 GitHub 下载解释器。本机是 3.12/3.13 时用：

```powershell
uv run --no-project --python 3.13 --with alphagenome --with absl-py --with python-dotenv --with tabulate --with anndata --with polars scripts\alphagenome_atlas_avi.py --help
```

**Q: 查看器页面白屏？**
Mol\* 从 jsdelivr CDN 加载，需要外网；离线环境无法使用（可改用 PyMOL 技能出 PNG）。

**Q: 查看器不是 DSH 侧边栏？**
是的，它是独立的本地网页。要做成原生面板需要写 DSH 客户端插件（见 docs/VIEWER-FEASIBILITY.md）。

**Q: 多个会话同时用查看器？**
`conversationId` 固定为 `dsh`，所有会话共享同一份视图状态。

---

## 十、来源与改动

- 技能来源：Google Antigravity 官方 science plugins（chemistry / genomics / scientific-literature / structural-biology / android-cli / science-overview），共 61 个 bundle，去重后 50 个技能。
- 对技能的改动：
  - Antigravity 工具名 → DSH 工具名：`view_file` → `read`、`write_to_file` → `write`、`read_url_content` → `web_fetch`，并移除只对 Antigravity 有意义的 `ArtifactMetadata` / `UserFacing` 参数。
  - `biomolecular-structure-viewer` 增加 DSH 使用章节。
- 对 MCP 的改动：关闭 Antigravity 会话强绑定（`conversationScoped: false`），数据目录支持 `BIOMOLECULAR_VIEWER_DATA_DIR` 环境变量与默认项目内路径。
- 详细记录见 `docs/`。

---

## 十一、许可证

本项目（打包结构、安装脚本、文档，以及对技能与 MCP 的适配改动）以
**[Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](LICENSE)** 发布，
Copyright (c) 2026 ff66ccff。

你可以自由地共享和改编，但必须：

- **署名**：注明来源与本仓库链接，并说明是否做了修改；
- **非商业**：不得将本作品用于商业目的。

完整法律条款见 [LICENSE](LICENSE)。

### 第三方内容与署名

- `skills/` 中的技能内容源自 Google Antigravity 官方 science plugins（chemistry、genomics、
  scientific-literature、structural-biology、android-cli、science-overview），版权归 Google 所有。
  本仓库做了工具名适配（`view_file` → `read`、`write_to_file` → `write`、`read_url_content` → `web_fetch`）、
  去重与文档补充，仅作非商业分发。
- `mcp/biomolecular_structure_viewer/` 同样来自该插件体系（作者 Google）。本仓库仅做了脱离
  Antigravity 宿主的最小改动：关闭会话强绑定（`conversationScoped: false`）、数据目录支持
  `BIOMOLECULAR_VIEWER_DATA_DIR` 与项目内默认路径。
- 运行时依赖（Mol\* / PDBe Mol\*、PyMOL、RDKit、uv 等）遵循各自许可证。

商业使用请联系上游权利人获取授权。
