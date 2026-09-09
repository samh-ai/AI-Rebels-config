# AI Rebels Config

## Project structure for agents and skills

Always place new subagents in `.Codex/agents/` and new skills in `.Codex/skills/`. Never create them in AppData, home directories, or any other location.

All URLs and git repos live in `registry.sh` — never hardcode them in `.sh` files.
