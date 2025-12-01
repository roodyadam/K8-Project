import os
from aim import Repo
from aim.cli.cli import cli_entry_point

# Initialize aim repo if it doesn't exist
aim_repo_path = '/opt/aim'
os.makedirs(aim_repo_path, exist_ok=True)
if not os.path.exists(os.path.join(aim_repo_path, '.aim')):
    try:
        repo = Repo.from_path(aim_repo_path, init=True)
    except:
        pass  # Repo might already exist

if __name__ == '__main__':
    cli_entry_point()