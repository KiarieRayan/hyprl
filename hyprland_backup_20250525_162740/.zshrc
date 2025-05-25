zmodload zsh/zprof


# Miniconda paths
export PATH="$HOME/tools/miniconda/bin:$PATH"

# Zinit plugin manager binaries
export PATH="$HOME/.local/share/zinit/polaris/bin:$PATH"

# Lua language server binaries
export PATH="$HOME/tools/lua-language-server/bin:$PATH"

# npm global binaries
export PATH="$HOME/.npm-global/bin:$PATH"

# At the VERY BOTTOM, add:
if (($+ZPROF_REPORT)); then
  zprof > ~/.zsh_startup.log
fi 

