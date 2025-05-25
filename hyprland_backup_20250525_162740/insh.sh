#!/usr/bin/env bash
set -euo pipefail


# --- CONFIGURATION ---
PYTHON_INSTALLED=false
SYSTEM_PYTHON=false
INSTALL_ANACONDA=false
ADD_TO_SYSTEM_PATH=true
USE_ZSH_SHELL=true
USE_BASH_SHELL=false

# --- UTILITY FUNCTIONS ---
die() {
    echo "ERROR: $*" >&2
    exit 1
}

safe_curl() {
    # Try normal download first
    if curl -fsSL "$1" -o "$2"; then
        return 0
    fi
    
    echo "WARNING: Standard download failed, trying insecure fallback for $1"
    if ! curl -fsSLk "$1" -o "$2"; then
        die "Failed to download $1 (both secure and insecure methods)"
    fi
}

append_to_rc() {
    local line="$1"
    local rc_file
    
    if [[ "$USE_ZSH_SHELL" == true ]]; then
        rc_file="$HOME/.zshrc"
    elif [[ "$USE_BASH_SHELL" == true ]]; then
        rc_file="$HOME/.bash_profile"
    else
        return 0
    fi
    
    grep -qxF "$line" "$rc_file" || echo "$line" >> "$rc_file"
}

download_and_extract() {
    local url="$1"
    local dest="$2"
    local strip="${3:-0}"
    local compression="${4:-gz}"
    
    echo "Downloading $url"
    local temp_file
    temp_file=$(mktemp)
    
    safe_curl "$url" "$temp_file"
    
    case "$compression" in
        gz) tar_cmd="tar -xz" ;;
        xz) tar_cmd="tar -xJ" ;;
        *) die "Unsupported compression: $compression" ;;
    esac
    
    if ! $tar_cmd -C "$dest" --strip-components="$strip" -f "$temp_file"; then
        rm -f "$temp_file"
        die "Failed to extract archive"
    fi
    
    rm -f "$temp_file"
}

# --- Conda Install ---
if [[ "$PYTHON_INSTALLED" == false ]]; then
    echo "Installing conda..."
    if [[ "$INSTALL_ANACONDA" == true ]]; then
        CONDA_NAME=Anaconda3-2021.11-Linux-x86_64.sh
        CONDA_LINK="https://repo.anaconda.com/archive/$CONDA_NAME"
        CONDA_DIR="$HOME/tools/anaconda"
    else
        CONDA_NAME=Miniconda3-py39_4.10.3-Linux-x86_64.sh
        CONDA_LINK="https://repo.anaconda.com/miniconda/$CONDA_NAME"
        CONDA_DIR="$HOME/tools/miniconda"
    fi
    
    safe_curl "$CONDA_LINK" "$HOME/packages/$CONDA_NAME"
    rm -rf "$CONDA_DIR"
    bash "$HOME/packages/$CONDA_NAME" -b -p "$CONDA_DIR" || die "Conda installation failed"
    [[ "$ADD_TO_SYSTEM_PATH" == true ]] && append_to_rc "export PATH=\"$CONDA_DIR/bin:\$PATH\""
else
    echo "Skipping conda installation"
fi

# --- Python Packages ---
PY_PACKAGES=(pynvim "python-lsp-server[all]" vim-vint python-lsp-isort pylsp-mypy python-lsp-black)
if [[ "$SYSTEM_PYTHON" == true ]]; then
    echo "Installing Python packages to user site"
    for pkg in "${PY_PACKAGES[@]}"; do
        pip install --user "$pkg" || die "Failed to install $pkg"
    done
else
    echo "Installing Python packages via conda"
    CONDA_PIP="${CONDA_DIR:-$HOME/tools/miniconda}/bin/pip"
    for pkg in "${PY_PACKAGES[@]}"; do
        "$CONDA_PIP" install "$pkg" || die "Failed to install $pkg"
    done
fi

# --- Node.js ---
NODE_DIR="$HOME/tools/nodejs"
NODE_VERSION="18.16.0"
NODE_LINK="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
if ! command -v node &>/dev/null; then
    echo "Installing Node.js..."
    mkdir -p "$NODE_DIR"
    download_and_extract "$NODE_LINK" "$NODE_DIR" 1 "xz"
    [[ "$ADD_TO_SYSTEM_PATH" == true ]] && append_to_rc "export PATH=\"$NODE_DIR/bin:\$PATH\""
else
    NODE_DIR=$(dirname "$(dirname "$(command -v node)")")
    echo "Node.js already installed"
fi

npm install -g vim-language-server bash-language-server || die "Failed to install language servers"

# --- Lua Language Server ---
LUA_LS_DIR="$HOME/tools/lua-language-server"
LUA_LS_VERSION="3.6.11"
LUA_LS_LINK="https://github.com/LuaLS/lua-language-server/releases/download/$LUA_LS_VERSION/lua-language-server-$LUA_LS_VERSION-linux-x64.tar.gz"
if ! command -v lua-language-server &>/dev/null; then
    echo "Installing Lua Language Server..."
    mkdir -p "$LUA_LS_DIR"
    download_and_extract "$LUA_LS_LINK" "$LUA_LS_DIR"
    [[ "$ADD_TO_SYSTEM_PATH" == true ]] && append_to_rc "export PATH=\"$LUA_LS_DIR/bin:\$PATH\""
else
    echo "Lua Language Server already installed"
fi

# --- ripgrep ---
RIPGREP_DIR="$HOME/tools/ripgrep"
RIPGREP_VERSION="13.0.0"
RIPGREP_LINK="https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep-$RIPGREP_VERSION-x86_64-unknown-linux-musl.tar.gz"
if ! command -v rg &>/dev/null; then
    echo "Installing ripgrep..."
    mkdir -p "$RIPGREP_DIR"
    download_and_extract "$RIPGREP_LINK" "$RIPGREP_DIR" 1
    [[ "$ADD_TO_SYSTEM_PATH" == true ]] && append_to_rc "export PATH=\"$RIPGREP_DIR:\$PATH\""
    mkdir -p "$RIPGREP_DIR/doc/man/man1"
    mv "$RIPGREP_DIR/doc/rg.1" "$RIPGREP_DIR/doc/man/man1/"
    [[ "$USE_ZSH_SHELL" == true ]] && append_to_rc "export FPATH=\"$RIPGREP_DIR/complete:\$FPATH\""
else
    echo "ripgrep already installed"
fi

# --- Neovim ---
NVIM_DIR="$HOME/tools/nvim"
NVIM_LINK="https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz"
if ! command -v nvim &>/dev/null; then
    echo "Installing Neovim..."
    mkdir -p "$NVIM_DIR"
    download_and_extract "$NVIM_LINK" "$NVIM_DIR" 1
    [[ "$ADD_TO_SYSTEM_PATH" == true ]] && append_to_rc "export PATH=\"$NVIM_DIR/bin:\$PATH\""
else
    echo "Neovim already installed"
fi

# --- Neovim Config ---
NVIM_CONFIG_DIR="$HOME/.config/nvim"
if [[ -d "$NVIM_CONFIG_DIR" ]]; then
    echo "Backing up existing config"
    mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.backup"
fi

git clone --depth=1 https://github.com/jdhao/nvim-config.git "$NVIM_CONFIG_DIR" || die "Failed to clone nvim config"

echo "Installing plugins..."
if [[ -f "$NVIM_DIR/bin/nvim" ]]; then
    "$NVIM_DIR/bin/nvim" -c "autocmd User LazyInstall quitall" -c "lua require('lazy').install()"
else
    echo "WARNING: Could not find nvim binary to install plugins"
fi

echo "Installation complete!"
