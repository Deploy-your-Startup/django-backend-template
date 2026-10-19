"""GIVEN the real Markdown instructions, WHEN following every relative link, THEN each target exists.

Agent instructions stay short by linking to the documents that hold the details.
This check keeps those links working and the ADR index complete; it deliberately
asserts no wording beyond the ADR headings.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIPPED_DIRECTORIES = {".git", "node_modules", ".venv", "dist", "build", ".pytest_cache"}
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
IMPORT = re.compile(r"^@(\S+)$", re.MULTILINE)
ADR_NAME = re.compile(r"^(\d{4})-[a-z0-9-]+\.md$")
ADR_INDEX = re.compile(r"^## Architecture decisions$(.*?)(?=^## |\Z)", re.MULTILINE | re.DOTALL)
ADR_HEADINGS = ("## Context", "## Decision", "## Consequences", "## Alternatives considered")


def markdown_files():
    for path in sorted(ROOT.rglob("*.md")):
        if not SKIPPED_DIRECTORIES.intersection(path.relative_to(ROOT).parts):
            yield path


def broken_links(document):
    text = re.sub(r"```.*?```", "", document.read_text(), flags=re.DOTALL)
    targets = LINK.findall(text) + IMPORT.findall(text)
    for target in targets:
        if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#") or "{{" in target:
            continue
        path = target.split("#", 1)[0]
        if path and not (document.parent / path).exists():
            yield f"{document.relative_to(ROOT)} → {target}"


def test_relative_links_resolve():
    # GIVEN every Markdown document in this standalone repository.
    documents = list(markdown_files())
    # WHEN following their relative links and @ imports.
    broken = [link for document in documents for link in broken_links(document)]
    # THEN every target exists, so short instructions lead to their details.
    assert not broken, "Broken links:\n" + "\n".join(broken)


def test_agent_instructions_link_the_testing_policy():
    # GIVEN each agent entrypoint that sits next to a testing policy,
    # WHEN looking for the policy it delegates to,
    # THEN it links the policy instead of restating it.
    for policy in ROOT.rglob("docs/testing-policy.md"):
        instructions = policy.parent.parent / "AGENTS.md"
        if SKIPPED_DIRECTORIES.intersection(policy.relative_to(ROOT).parts) or not instructions.exists():
            continue
        assert "](docs/testing-policy.md)" in instructions.read_text(), (
            f"{instructions.relative_to(ROOT)} must link docs/testing-policy.md"
        )


def architecture_decision_problems(directory):
    instructions = directory.parent.parent / "AGENTS.md"
    records = sorted(directory.glob("*.md"))
    numbers = {}
    for record in records:
        name = ADR_NAME.match(record.name)
        if not name:
            yield f"{record.relative_to(ROOT)}: name it NNNN-short-title.md"
            continue
        numbers.setdefault(name.group(1), []).append(record.name)
        text = record.read_text()
        if not re.search(r"^\*\*Status\*\*: \S", text, re.MULTILINE):
            yield f"{record.relative_to(ROOT)}: missing '**Status**: <status>' line"
        for heading in ADR_HEADINGS:
            if not re.search(rf"^{re.escape(heading)}$", text, re.MULTILINE):
                yield f"{record.relative_to(ROOT)}: missing '{heading}' section"
    for number, names in numbers.items():
        if len(names) > 1:
            yield f"ADR {number} is used more than once: {', '.join(names)}"
    index = ADR_INDEX.search(instructions.read_text()) if instructions.exists() else None
    if not index:
        yield f"{instructions.relative_to(ROOT)}: missing '## Architecture decisions' section"
        return
    listed = {(instructions.parent / target.split("#", 1)[0]).resolve() for target in LINK.findall(index.group(1))}
    for record in records:
        if record.resolve() not in listed:
            yield f"{record.relative_to(ROOT)} is not listed under '## Architecture decisions'"


def test_architecture_decisions_are_unique_complete_and_listed():
    # GIVEN every docs/architecture directory next to an AGENTS.md, including
    # template ADRs (0001-0099) and project ADRs (0100 and up) side by side.
    directories = [
        directory
        for directory in sorted(ROOT.rglob("docs/architecture"))
        if directory.is_dir() and not SKIPPED_DIRECTORIES.intersection(directory.relative_to(ROOT).parts)
    ]
    # WHEN checking their names, headings and the AGENTS.md index.
    problems = [problem for directory in directories for problem in architecture_decision_problems(directory)]
    # THEN numbers are unique, each record is complete and every record is
    # listed, so a template update cannot silently collide with a project ADR.
    assert not problems, "Architecture decision problems:\n" + "\n".join(problems)


if __name__ == "__main__":
    for check in (
        test_relative_links_resolve,
        test_agent_instructions_link_the_testing_policy,
        test_architecture_decisions_are_unique_complete_and_listed,
    ):
        check()
    print("Agent instruction links resolve, delegate to the testing policy and list every ADR.")
    sys.exit(0)
