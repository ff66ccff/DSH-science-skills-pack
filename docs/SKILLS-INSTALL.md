# DSH Science Skills Pack — 技能安装与验证记录

- 来源：`google-plugin-skills.zip`（61 个 skill bundle / 402 个条目）
- 安装位置：`<PROJECT>\.dsh\skills\`（项目级根目录，rank 100，优先于用户级 `~/.dsh/skills`）
- 生效条件：DSH 以 `<PROJECT>` 为 cwd（无 `.git` 时 projectRoot 即 cwd）时自动发现
- 安装结果：61 个 bundle 去重后 **50 个 skills**，全部通过 frontmatter 校验并进入会话目录

## 目录约定（DSH 的发现规则）

1. 只扫描 `<projectRoot>/.dsh/skills` 的**直接子项**：
   - 目录包：`<dir>/SKILL.md`（**不会递归**，所以 zip 里的 `chemistry/xxx/SKILL.md` 必须先拍平）
   - 扁平文件：`<name>.md`
2. skill 名取自 SKILL.md frontmatter 的 `name`，必须是 kebab-case（`^[a-z0-9]+(?:-[a-z0-9]+)*$`）；目录名不参与命名。
3. frontmatter 必须有 `name` 与 `description`；可选 `whenToUse`、`disable-model-invocation`、`user-invocable`、`metadata`。

因此安装时**保留原始目录名（snake_case）**，这样化学系列技能内部的相对引用
（如 `../rdkit_general/scripts/draw_molecules.py`）在拍平后仍然成立。

## 去重（内容逐字节相同，只保留一份）

| skill | 原始位置 |
|---|---|
| credentials | chemistry / genomics / scientific-literature / structural-biology |
| uv | 同上 4 个分类 |
| workflow-skill-creator | 同上 4 个分类 |
| literature-search-openalex | chemistry / scientific-literature |
| pubmed-database | chemistry / scientific-literature |

## 验证记录

- `skill` 工具加载：`uv` 返回正文，`resourceBase` = `<PROJECT>\.dsh\skills\uv`。
- 真实脚本调用：
  - `uv run pubchem_api.py resolve --name aspirin --output ...` → 返回 CID 2244 / InChIKey BSYNRYMUTXBXSQ-UHFFFAOYSA-N（联网正常）
  - `uv run draw_molecules.py --smiles 'CC(=O)OC1=CC=CC=C1C(=O)O' --output ...` → 生成 2D 结构 PNG
  - `uv run clinvar_api.py --help` → 正常
- PEP 723 依赖由 `uv run` 自动安装（rdkit / pandas / numpy / polite-http 等）。

## 已知限制

- `biomolecular-structure-viewer` 依赖 Antigravity 的 `structural-biology_structure_viewer_mcp` 工具，本机 DSH 无该 MCP，只能加载不能执行。
- 需要 API Key 的技能（11 个提及 key）：`ALPHAGENOME_API_KEY` 等，未配置时会失败。
- `android-cli` 需要单独安装 `android` CLI（本机 `agy`/`antigravity` 存在，`android` 不存在）。
- `pymol`：已实测。按技能说明写了 `render.py`（PEP 723 + `pymol-open-source-whl`），`uv run` 自动装包，成功渲染 1CRN（327 atoms）并输出 PNG + `.pse`，见 `.dsh/verify/pymol/`。
- Antigravity 产物（`<artifact_dir>`、`.html.metadata.json` 的 `userFacing`）在 DSH 无对应 UI 概念，仅保留为普通文件/链接。

## 工具名适配（Antigravity → DSH）

已把技能正文里 Antigravity 的工具名替换为 DSH 等价工具，共改 7 个文件：

| 原工具名 | DSH 工具 | 处数 |
|---|---|---|
| `view_file` | `read` | 4 处 / 3 文件（cheminformatics_core、doc2mol、physics） |
| `write_to_file` | `write` | 5 处 / 4 文件（cheminformatics_core、rdkit_general 及其 references） |
| `read_url_content` | `web_fetch` | 1 处 / 1 文件（biomolecular_structure_viewer） |

同时删除了只对 Antigravity 有意义的调用参数（`ArtifactMetadata={...}`、`(UserFacing: True)`），
改为「用 `write` 创建占位文件 → 运行脚本填充 → 在报告中链到 `<artifact_dir>/`」的 DSH 可执行表述。
已复核：50 个 SKILL.md frontmatter 全部有效，无残留旧工具名。

## API Key 现状（实测）

用户已手动注册 AlphaGenome 免费 key，并写入 `%USERPROFILE%\.env`（单行、ASCII 无 BOM，未回显、未入库到本文件）。

**实测通过**：`alphagenome_atlas_avi.py query "chr9:128225994:G>A" --format json` 返回
AVI phred 24.66 / raw 1.061 / top modality = Splicing（fi 0.770），结果见 `.dsh/verify/alphagenome/avi.json`。

> 安全提醒：该 key 曾出现在对话里，建议验证完成后到 AlphaGenome 控制台轮换（revoke + 重新生成），
> 再用同样的隐藏输入方式更新 `~/.env`。

**无 key 也能正常跑（实测）**：`literature-search-openalex`（返回 no-key 共享配额提示）、
`pubmed-database`（NCBI 无需 key）、`openfda-database`（仅限速警告）、`pubchem-database`、`clinvar-database`。

**AlphaGenome 环境另有一个坑**：`alphagenome_variant_impact_score` / `alphagenome_single_variant_analysis` 的 `pyproject.toml` 要求
`requires-python = ">=3.14"`，本机只有 3.12/3.13，`uv run` 会去 GitHub 下载 CPython 3.14 并因证书错误失败
（`invalid peer certificate: UnknownIssuer`）。实测 `alphagenome` 在 3.13 可正常导入，可绕过项目 pin：

```powershell
uv run --no-project --python 3.13 --with alphagenome --with absl-py --with python-dotenv --with tabulate --with anndata --with polars scripts/alphagenome_atlas_avi.py --help
```

无 key 时脚本报错明确：`ValueError: ALPHAGENOME_API_KEY environment variable not set.`（说明除 key 外链路已通）。

**真正必须 key**：`alphagenome-*`（`ALPHAGENOME_API_KEY`，且需按技能说明建 `alphagenome` 环境）、
`cheminformatics-cofolding` 的 Boltz API 推理（`BOLTZ_API_KEY`）、
`cheminformatics-core` 的采购报价（`chemspace_api_key` / `molport_api_key` / `MCULE_API_KEY`）。
其余 `NCBI_API_KEY`、`OPENALEX_API_KEY`、`FDA_API_KEY`、`NCBI_EMAIL`、`USER_EMAIL` 均为提额/礼貌用法，可选。

## 卸载 / 裁剪

删除 `<PROJECT>\.dsh\skills\<dir>` 即可；会话目录会在下一次 pre-step 自动刷新。
50 个技能约给每步增加 16.7k 字符（≈4.2k tokens）的目录开销，如只需部分能力，删掉无关目录即可。

## 备注

`.dsh/` 位于工作区内，若后续 `git init`，建议把 `.dsh/` 加入 `.gitignore`（脚本/二进制较多）。
