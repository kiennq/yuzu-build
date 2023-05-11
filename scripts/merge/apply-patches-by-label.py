# SPDX-FileCopyrightText: 2019 yuzu Emulator Project
# SPDX-License-Identifier: GPL-2.0-or-later

# Download all pull requests as patches that match a specific label
# Usage: python apply-patches-by-label.py <labels-to-match...> <tagline>

import json, requests, subprocess, sys, traceback, os

if len(sys.argv) < 2:
    print("Not enough parameter", file=sys.stderr)
    sys.exit(-1)

tagline = sys.argv[-1]
labels_to_match = sys.argv[:-1]
token = os.getenv('GITHUB_TOKEN')
merged_prs = []

def check_individual(labels):
    for label in labels:
        if (label["name"] in labels_to_match):
            return True
    return False

def do_page(page):
    url = f"https://api.github.com/repos/yuzu-emu/yuzu/pulls?page={page}"
    headers = {'authorization': f"Bearer {token}"} if token is not None else None
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    if (response.ok):
        j = json.loads(response.content)
        if j == []:
            return
        for pr in j:
            if (check_individual(pr["labels"])):
                pn = pr["number"]
                print(f"Matched PR# {pn}")
                print(subprocess.check_output(["git", "fetch", "https://github.com/yuzu-emu/yuzu.git", f"pull/{pn}/head:pr-{pn}", "-f", "--no-recurse-submodules"]))
                print(subprocess.check_output(["git", "merge", "--squash", f"pr-{pn}"]))
                print(subprocess.check_output(["git", "commit", f"-m\"Merge {tagline} PR {pn}\""]))
                merged_prs.append(pr["html_url"])

def release_note(file, prs):
    if prs == []:
        return
    file = open(file, 'w')
    file.write('This release include these EA PRs: \n')
    for pr in prs:
        file.write(f"  - {pr}\n")
    file.close()

try:
    for i in range(1,10):
        do_page(i)
    release_note(f"{os.getenv('GITHUB_WORKSPACE')}-CHANGELOG.txt", merged_prs)
except:
    traceback.print_exc(file=sys.stdout)
    sys.exit(-1)
