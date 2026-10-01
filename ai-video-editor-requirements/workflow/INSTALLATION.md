# Optional delivery skill

The repository already has an agent bootstrap. Do not replace its agents or skills wholesale.

For Claude Code, inspect the bundled `ai-video-editor-delivery/SKILL.md` and references. When useful, copy that one directory into `.claude/skills/ai-video-editor-delivery/`, preserving the `SKILL.md` and `references/` structure. Merge overlaps with existing implementation/verification skills. The `agents/openai.yaml` file is portable ChatGPT skill UI metadata and is not a required Claude Code configuration file.

The separate `skill.zip` contains exactly this one self-contained skill. No connector is required; it needs a repository-capable code execution environment. It locates the requirements package and uses the existing working-document mapping.

The skill includes no hard-coded native workflow API or hook configuration. The implementing agent must validate actual current tool support before adding such configuration. A pure chat environment without a writable repository cannot execute the delivery workflow.
