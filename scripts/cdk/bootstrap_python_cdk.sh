set -exo pipefail
if [[ -z $1 ]]; then
    echo "Pass in the repo name as argument"
    exit 1
fi

mkdir $1
cd $1
git init

mkdir -p src/app
mkdir -p src/infra

# Create Python virtual env
python -m venv .venv
source .venv/bin/activate

# Init CDK app
pushd src/infra
cdk init app --language=python --generateOnly
rm -rf tests
pip install -r requirements.txt
popd

# Move .gitignore and README to root
mv src/infra/.gitignore .
mv src/infra/README.md .
mv src/infra/requirements*.txt .
mv src/infra/source.bat .

# Pre-commit config
pip install pre-commit
pre-commit --version
cat << EOF > .pre-commit-config.yaml
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v2.3.0
    hooks:
    -   id: end-of-file-fixer
    -   id: trailing-whitespace
-   repo: https://github.com/psf/black
    rev: 22.12.0
    hooks:
    -   id: black
        args: [
            '--line-length=120',
            '--exclude', '/(\.direnv|\.eggs|\.git|\.hg|\.mypy_cache|\.nox|\.tox|\.venv|\.ipynb_checkpoints|cdk.out|dist|__pypackages__)/'
            ]
-   repo: https://github.com/pycqa/flake8
    rev: 6.0.0
    hooks:
    -   id: flake8
        args: # arguments to configure flake8
            - "--max-line-length=120"
            - "--max-complexity=10"
            - "--select=B,C,E,F,W,T4,B9"
            - "--ignore=F401"
EOF
pre-commit install
pre-commit run --all-files

echo "Setup remote origin: git remote add origin https://github.com/USER/REPO.git"