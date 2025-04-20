#!/usr/bin/env python3

import argparse
import os
import sys
import re
from tempfile import NamedTemporaryFile
from ansible.parsing.vault import VaultEditor, VaultLib, VaultSecret
from ansible.constants import DEFAULT_VAULT_IDENTITY

def rotate_password(content, old_secret, new_secret):
    # Regular expression to find vault blocks in the content
    vault_regex = re.compile(r'(^(\s*)\$ANSIBLE_VAULT\S*\n(\s*\w+\n)*)', re.MULTILINE)
    vaults = {match[0]: match[1] for match in vault_regex.findall(content)}
    # Iterate through all vault blocks
    for old_vault, indentation in vaults.items():
        # Create a temporary file and write the old vault content
        with NamedTemporaryFile(mode='w', delete=False) as temporary_file:
            temporary_file.write(old_vault.replace(indentation, ''))
        # Open the vault with the old password and re-encrypt with the new password
        VaultEditor(VaultLib([(DEFAULT_VAULT_IDENTITY, old_secret)])).rekey_file(temporary_file.name, new_secret)
        # Read the new vault content and insert it into the original content
        with open(temporary_file.name) as temporary_file:
            new_vault = indentation + indentation.join(temporary_file.readlines())
            content = content.replace(old_vault, new_vault)
    return content

def main(old_password, new_password):
    new_contents = []
    # Iterate through all files in the current directory
    for root, subdirs, files in os.walk('.'):
        for file in files:
            print('Processing file: {}'.format(file))
            file_path = os.path.join(root, file)
            # Read the file content
            with open(file_path) as f:
                content = f.read()
            # Re-encrypt the file content with the new password and overwrite it
            new_content = None
            try:
                new_content = rotate_password(content, VaultSecret(old_password.encode()), VaultSecret(new_password.encode()))
            except Exception as e:
                print(f"Something went wrong while parsing File '{file_path}' Error: {e}")
                sys.exit(1)
            if new_content:
                new_contents.append((file_path, new_content))
    # Write the new file contents
    for file_path, new_content in new_contents:
        with open(file_path, 'w') as f:
            f.write(new_content)

# Call the main program with the command-line arguments provided
if __name__ == '__main__':
    # Read vault passwords from command-line arguments
    parser = argparse.ArgumentParser(description='Rotate vault password')
    parser.add_argument('--old_password', help='old vault password')
    parser.add_argument('--new_password', help='new vault password')
    args = parser.parse_args()
    main(args.old_password, args.new_password)
