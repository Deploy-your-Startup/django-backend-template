#!/usr/bin/env python3
"""
Rotate Ansible vault passwords for files (full vault files or inline vault blocks).
Features:
- Atomic writes (no .tmp backups)
- Pathlib usage
- Structured logging with levels
- Dry-run mode
- Regex-based inline block handling (no ruamel.yaml)
- Subcommands: rotate (all or specific file), status
"""

import argparse
import logging
import shutil
import sys
import re
from pathlib import Path
from tempfile import NamedTemporaryFile

from ansible.parsing.vault import VaultEditor, VaultLib, VaultSecret
from ansible.constants import DEFAULT_VAULT_IDENTITY

# Patterns for excluding files/directories
EXCLUDED_PATTERNS = [
    "*.pyc",
    "__pycache__",
    ".git",
    "*.swp",
]

logger = logging.getLogger(__name__)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Rotate Ansible vault passwords"
    )
    parser.add_argument(
        "--old-password", "-o", required=True, help="Old vault password"
    )
    parser.add_argument(
        "--new-password", "-n", required=True, help="New vault password"
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="Don't write changes, only report"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Verbose (DEBUG) logging"
    )
    parser.add_argument(
        "--jobs", "-j", type=int, default=1, help="Number of parallel jobs (not used)"
    )

    subparsers = parser.add_subparsers(dest="command", required=True)
    rotate = subparsers.add_parser("rotate", help="Rotate vault passwords")
    rotate.add_argument(
        "file", nargs="?", type=Path, help="Specific file to rotate (optional)"
    )
    subparsers.add_parser("status", help="List files with vaulted content")

    return parser.parse_args()


def setup_logging(verbose: bool):
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)-8s %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )


def safe_write(path: Path, content: str):
    """Atomically write content to a file (no backups)."""
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content, encoding="utf-8")
    tmp.replace(path)
    logger.info(f"Updated: {path}")


def is_excluded(path: Path) -> bool:
    for pat in EXCLUDED_PATTERNS:
        if path.match(pat):
            return True
    return False


def walk_files(base: Path, specific: Path = None):
    if specific:
        if specific.is_file() and not is_excluded(specific):
            yield specific
        return
    for path in base.rglob("*"):
        if path.is_file() and not is_excluded(path):
            yield path


def is_full_vault_file(path: Path) -> bool:
    try:
        first_line = path.read_text(encoding="utf-8").splitlines()[0]
        return first_line.startswith("$ANSIBLE_VAULT")
    except Exception:
        return False


def list_status(args):
    for path in walk_files(Path('.'), getattr(args, 'file', None)):
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
            if text.startswith("$ANSIBLE_VAULT") or "!vault" in text:
                print(path)
        except Exception as e:
            logger.warning(f"Could not read {path}: {e}")


def rotate_full_file(path: Path, old_secret: VaultSecret, new_secret: VaultSecret, dry_run: bool):
    if dry_run:
        logger.info(f"[DRY-RUN] Would rotate full vault file: {path}")
        return
    try:
        VaultEditor(VaultLib([(DEFAULT_VAULT_IDENTITY, old_secret)])).rekey_file(str(path), new_secret)
        logger.info(f"Rotated vault file: {path}")
    except Exception as e:
        logger.error(f"Error rotating vault file {path}: {e}")


def rotate_inline_blocks(text: str, old_secret: VaultSecret, new_secret: VaultSecret) -> str:
    if not text.endswith('\n'):
        text += '\n'

    # Regex to match !vault | blocks including final line without newline
    multiline_regex = re.compile(
        r'(?P<key>^\s*[^\s].*?:\s*)(?P<marker>!vault\s*\|)[\r\n]+'
        r'(?P<content>(?P<indent>\s*)(?:\$ANSIBLE_VAULT[^\r\n]*[\r\n]+)'
        r'(?:\s*[0-9A-Fa-f]+(?:[\r\n]+|$))+)',
        re.MULTILINE
    )

    def repl(m):
        key = m.group('key')
        indent = m.group('indent')
        raw = m.group('content')
        # strip indent
        block = ''.join(line[len(indent):] for line in raw.splitlines(True))
        if not block.endswith('\n'):
            block += '\n'
        # write to temp, rekey
        with NamedTemporaryFile(mode='w+', delete=False) as tmp:
            tmp.write(block)
            tmp.flush()
            tmp_path = tmp.name
        VaultEditor(VaultLib([(DEFAULT_VAULT_IDENTITY, old_secret)])).rekey_file(tmp_path, new_secret)
        new_block_lines = Path(tmp_path).read_text().splitlines(True)
        Path(tmp_path).unlink()
        # re-indent
        recoded = ''.join(indent + line for line in new_block_lines)
        return f"{key}!vault |\n{recoded}"

    return multiline_regex.sub(repl, text)


def rotate_all(args):
    old_secret = VaultSecret(args.old_password.encode())
    new_secret = VaultSecret(args.new_password.encode())

    for path in walk_files(Path('.'), getattr(args, 'file', None)):
        try:
            if is_full_vault_file(path):
                rotate_full_file(path, old_secret, new_secret, args.dry_run)
            else:
                text = path.read_text(encoding="utf-8", errors="ignore")
                if "$ANSIBLE_VAULT" in text or "!vault" in text:
                    new_text = rotate_inline_blocks(text, old_secret, new_secret)
                    if new_text != text:
                        if args.dry_run:
                            logger.info(f"[DRY-RUN] Would update: {path}")
                        else:
                            safe_write(path, new_text)
        except Exception as e:
            logger.error(f"Error processing {path}: {e}")


def main():
    args = parse_args()
    setup_logging(args.verbose)
    if args.command == "status":
        list_status(args)
    elif args.command == "rotate":
        rotate_all(args)


if __name__ == "__main__":
    main()
