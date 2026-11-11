#!/bin/sh

# Set up a virtual Python environment and linters for development.

set -e
cd "$(dirname "$0")"
venv_dir='.venv'
github='https://github.com'


# Virtual environment.
if ! "$venv_dir/bin/python" -c 'import pip' 2>/dev/null; then
    python=$(
        find /usr/bin/ /usr/local/bin/ -name 'python*' 2>/dev/null |
        sed -n 's|.*/\(python[0-9.]*\)$|\1|p' |
        sort -V |
        tail -n1
    )
    "$python" -m venv --clear "$venv_dir"
    "$venv_dir/bin/python" -m pip install -U pip
fi
. "$venv_dir/bin/activate"


# Packages.
pip install -r requirements.txt


# Static Biome linter and formatter.
f="$venv_dir/bin/biome"
if [ ! -x "$f" ]; then
    url="$github/biomejs/biome/releases/latest/download/biome-linux-x64-musl"
    curl -fLo "$f.temp" "$url"
    chmod a+x "$f.temp"
    mv "$f.temp" "$f"
fi


# Nu Html Checker. Needs Java.
jar="$venv_dir/vnu.jar"
f="$venv_dir/bin/vnu"
if [ ! -f "$jar" ]; then
    url="$github/validator/validator/releases/latest/download/vnu.jar"
    curl -fLo "$jar.temp" "$url"
    mv "$jar.temp" "$jar"
fi
cat >"$f" <<EOF
#!/bin/sh
exec java -jar "$PWD/$jar" "\$@"
EOF
chmod a+x "$f"


# Git hooks. Relative symlinks, so edits apply without rerunning setup.
if [ -d .git/hooks ]; then
    for f in hooks/*; do
        ln -sfn "../../$f" ".git/hooks/${f#hooks/}"
    done
fi


# Environment manager.
cat >.envrc <<EOF
venv_dir='$venv_dir'
if [ -d "\$venv_dir/bin" ]; then
    export VIRTUAL_ENV="\$PWD/\$venv_dir"
    PATH_add "\$VIRTUAL_ENV/bin"
fi
EOF
