#!/bin/bash
# ==============================================================================
# Setup — ZorinOS 18 / Linux Mint
# Flatpaks + Linuxbrew + NVM + Node.js + Docker
# SEM .deb, SEM tocar em pacotes do sistema
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}[✔]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
info()    { echo -e "${BLUE}[»]${NC} $1"; }
section() { echo -e "\n${MAGENTA}${BOLD}══════════════════════════════════════${NC}"
            echo -e "${MAGENTA}${BOLD}  $1${NC}"
            echo -e "${MAGENTA}${BOLD}══════════════════════════════════════${NC}"; }
error()   { echo -e "${RED}[✘]${NC} $1"; exit 1; }
skip()    { echo -e "${CYAN}[~]${NC} $1 já instalado, pulando."; }

[ "$EUID" -eq 0 ] && error "Não execute como root."

# Sudo keepalive
sudo -v || error "Falha na autenticação sudo."
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# ==============================================================================
# 1. FLATPAKS — instalação em lote
# ==============================================================================
section "1 · Flatpaks"

info "Instalando todos os Flatpaks em lote..."

flatpak install -y --noninteractive flathub \
  org.localsend.localsend_app          \
  md.obsidian.Obsidian                 \
  io.appflowy.AppFlowy                 \
  io.github.alainm23.planify           \
  org.gnome.Solanum                    \
  org.gnome.World.PikaBackup           \
  io.bassi.Amberol                     \
  com.spotify.Client                   \
  org.kde.kdenlive                     \
  org.blender.Blender                  \
  org.gimp.GIMP                        \
  org.inkscape.Inkscape                \
  com.github.finefindus.eyedropper     \
  com.github.huluti.Curtail            \
  fr.handbrake.ghb                     \
  org.videolan.VLC                     \
  com.google.AndroidStudio             \
  dev.zed.Zed                          \
  com.usebruno.Bruno                   \
  io.beekeeperstudio.Studio            \
  io.podman_desktop.PodmanDesktop      \
  it.mijorus.gearlever                 \
  app.devsuite.Ptyxis                  \
  com.github.flxzt.rnote               \
  org.gaphor.Gaphor                    \
  ai.jan.Jan                           \
  io.missioncenter.MissionCenter       \
  || warn "Alguns Flatpaks falharam. Verifique manualmente no Flathub."

log "Flatpaks instalados."

# ==============================================================================
# 2. LINUXBREW
# ==============================================================================
section "2 · Linuxbrew"

if command -v brew &>/dev/null; then
  skip "Linuxbrew"
else
  info "Instalando Linuxbrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  BREW_PREFIX="/home/linuxbrew/.linuxbrew"
  [ -d "$BREW_PREFIX" ] || BREW_PREFIX="$HOME/.linuxbrew"

  BREW_INIT="eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""
  grep -qF 'brew shellenv' ~/.bashrc  || echo -e "\n$BREW_INIT" >> ~/.bashrc
  grep -qF 'brew shellenv' ~/.profile || echo -e "\n$BREW_INIT" >> ~/.profile
  { [ -f ~/.zshrc ] && grep -qF 'brew shellenv' ~/.zshrc; } \
    || { [ -f ~/.zshrc ] && echo -e "\n$BREW_INIT" >> ~/.zshrc; }

  eval "$($BREW_PREFIX/bin/brew shellenv)"
  log "Linuxbrew instalado."
fi

info "Instalando ferramentas via Brew..."
brew install \
  gh \
  git \
  fzf \
  bat \
  eza \
  zoxide \
  ripgrep \
  fd \
  htop \
  jq \
  tldr \
  lazygit \
  || warn "Algumas ferramentas Brew falharam."

log "Ferramentas Brew instaladas."

# ==============================================================================
# 3. NVM + NODE.JS LTS
# ==============================================================================
section "3 · NVM + Node.js LTS"

export NVM_DIR="$HOME/.nvm"

if [ -d "$NVM_DIR" ]; then
  skip "NVM"
else
  info "Instalando NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  log "NVM instalado."
fi

set +u
[ -s "$NVM_DIR/nvm.sh" ]          && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

info "Instalando Node.js LTS..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
set -u

log "Node.js $(node -v) | NPM $(npm -v)"

NVM_INIT='export NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.bashrc \
  || echo -e "\n$NVM_INIT" >> ~/.bashrc
{ [ -f ~/.zshrc ] && grep -qxF 'export NVM_DIR="$HOME/.nvm"' ~/.zshrc; } \
  || { [ -f ~/.zshrc ] && echo -e "\n$NVM_INIT" >> ~/.zshrc; }

info "Instalando ferramentas globais npm..."
npm install -g \
  expo-cli \
  eas-cli \
  typescript \
  ts-node \
  prettier \
  eslint \
  || warn "Algumas ferramentas npm falharam."
log "Ferramentas npm instaladas."

# ==============================================================================
# 4. FLUTTER SDK
# ==============================================================================
section "4 · Flutter SDK"

FLUTTER_DIR="$HOME/development/flutter"

if command -v flutter &>/dev/null; then
  skip "Flutter SDK"
else
  info "Instalando Flutter SDK..."
  mkdir -p "$HOME/development"
  git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
  export PATH="$PATH:$FLUTTER_DIR/bin"

  grep -q 'flutter/bin' ~/.bashrc \
    || echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.bashrc
  { [ -f ~/.zshrc ] && grep -q 'flutter/bin' ~/.zshrc; } \
    || { [ -f ~/.zshrc ] \
         && echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc; }

  flutter precache 2>/dev/null || true
  log "Flutter SDK instalado em $FLUTTER_DIR"
fi

# ==============================================================================
# 5. DOCKER CE — script oficial get.docker.com
# ==============================================================================
section "5 · Docker CE"

if command -v docker &>/dev/null; then
  skip "Docker"
else
  info "Instalando Docker via script oficial..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER"
  sudo systemctl enable docker
  sudo systemctl start docker
  log "Docker: $(docker --version)"
  warn "Logout/login necessário para ativar o grupo 'docker'."
fi

if ! docker compose version &>/dev/null 2>&1; then
  info "Instalando Docker Compose plugin..."
  DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
  mkdir -p "$DOCKER_CONFIG/cli-plugins"
  curl -fsSL \
    "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" \
    -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
  log "Docker Compose: $(docker compose version)"
fi

# ==============================================================================
# 6. OLLAMA + OPEN WEBUI
# ==============================================================================
section "6 · Ollama — IA Local"

if command -v ollama &>/dev/null; then
  skip "Ollama"
else
  info "Instalando Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
  log "Ollama instalado. Dica: ollama run llama3"
fi

if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^open-webui$"; then
  skip "Open WebUI"
else
  info "Instalando Open WebUI..."
  docker run -d \
    --name open-webui \
    --restart always \
    -p 3000:8080 \
    -v open-webui:/app/backend/data \
    --add-host=host.docker.internal:host-gateway \
    ghcr.io/open-webui/open-webui:main \
    || warn "Open WebUI: rode após logout/login para ativar Docker."
  log "Open WebUI → http://localhost:3000"
fi

# ==============================================================================
# 7. PENPOT
# ==============================================================================
section "7 · Penpot — Design Colaborativo"

PENPOT_DIR="$HOME/.local/share/penpot"

if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "penpot"; then
  skip "Penpot"
else
  info "Instalando Penpot..."
  mkdir -p "$PENPOT_DIR"
  curl -fsSL \
    https://raw.githubusercontent.com/penpot/penpot/main/docker/images/docker-compose.yaml \
    -o "$PENPOT_DIR/docker-compose.yaml" \
    || warn "Penpot: baixe manualmente em https://penpot.app/self-host"

  if [ -f "$PENPOT_DIR/docker-compose.yaml" ]; then
    docker compose -f "$PENPOT_DIR/docker-compose.yaml" up -d \
      || warn "Penpot: rode após logout/login:
       docker compose -f ~/.local/share/penpot/docker-compose.yaml up -d"
    log "Penpot → http://localhost:9001"
  fi
fi

# ==============================================================================
# RESUMO
# ==============================================================================
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║         Instalação concluída!                                ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Node.js    :${NC}  $(node -v 2>/dev/null || echo 'reinicie o terminal')"
echo -e "  ${BLUE}NPM        :${NC}  $(npm -v 2>/dev/null || echo 'reinicie o terminal')"
echo -e "  ${BLUE}Flutter    :${NC}  $(flutter --version 2>/dev/null | head -1 || echo 'reinicie o terminal')"
echo -e "  ${BLUE}Docker     :${NC}  $(docker --version 2>/dev/null || echo 'instalado')"
echo -e "  ${BLUE}Brew       :${NC}  $(brew --version 2>/dev/null | head -1 || echo 'reinicie o terminal')"
echo -e "  ${BLUE}Ollama     :${NC}  $(ollama --version 2>/dev/null || echo 'instalado')"
echo -e "  ${BLUE}Open WebUI :${NC}  http://localhost:3000"
echo -e "  ${BLUE}Penpot     :${NC}  http://localhost:9001"
echo ""
echo -e "${YELLOW}${BOLD}Próximos passos:${NC}"
echo -e "  ${YELLOW}1.${NC} ${CYAN}source ~/.bashrc${NC}  ou reinicie o terminal"
echo -e "  ${YELLOW}2.${NC} Logout/login para ativar o grupo 'docker'"
echo -e "  ${YELLOW}3.${NC} ${CYAN}flutter doctor${NC} para verificar o ambiente mobile"
echo -e "  ${YELLOW}4.${NC} ${CYAN}ollama run llama3${NC} para iniciar IA local"
echo ""
