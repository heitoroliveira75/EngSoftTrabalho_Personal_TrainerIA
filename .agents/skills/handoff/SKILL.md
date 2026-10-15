---
name: handoff
description: Compact details from the current conversation into a temporary handoff context file in the project root for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: false
---

Analyze the entire conversation history and create a temporary handoff document named `HANDOFF_TEMP.md` in the root of the current project workspace.

The document must act as a precise context bridge for another AI agent to resume the work immediately. Follow this strict Markdown structure:

# 🔄 AGY HANDOFF CONTEXT

## 🎯 Next Session Objective
[If the user passed arguments, use them here to explicitly define the focus of the next session. Otherwise, infer the immediate next step.]

## 📊 Current State & Artifacts
- List files created or modified. 
- You must format all file paths as relative paths starting from the project root directory (e.g., `src/components/Button.tsx`), ensuring they are universal across different machines.
- Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by their relative path or URL instead.

## 🧠 Decisions & Constraints
- List architectural or logic choices established in this session that should not be reopened or debated by the next agent.

## 🛠️ Suggested Skills
- Explicitly name which agy skills the next agent should call using the Skill tool to continue this work efficiently.

## ❌ Redacted Information
- [CRITICAL] Ensure all sensitive information such as API keys, secrets, tokens, passwords, or PII are completely redacted.

Save this file as `HANDOFF_TEMP.md` in the project root. Inform the user of the exact universal file path (relative to the project root, e.g., `./HANDOFF_TEMP.md`) and output a brief "Resume Prompt" they can copy and paste to wake up the next agent.
