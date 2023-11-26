#
# Cloudresty KubeCTL
#

# Base Image
FROM    debian:bookworm-slim

# Image details
LABEL   org.opencontainers.image.authors="Cloudresty" \
        org.opencontainers.image.url="https://hub.docker.com/r/cloudresty/kubectl" \
        org.opencontainers.image.source="https://github.com/cloudresty/kubectl" \
        org.opencontainers.image.version="v1.28.4" \
        org.opencontainers.image.revision="1.28.4-1.1" \
        org.opencontainers.image.vendor="Cloudresty" \
        org.opencontainers.image.licenses="MIT" \
        org.opencontainers.image.title="kubectl" \
        org.opencontainers.image.description="KubeCTL Container"

ENV     LC_ALL=C.UTF-8, LANG=C.UTF-8

# Update and Upgrade
RUN     apt-get update && \
        apt-get upgrade -y && \
        apt-get clean

# Install Packages
RUN     apt-get install -y \
        apt-transport-https \
        apparmor \
        apparmor-utils \
        ca-certificates \
        curl \
        git \
        gnupg \
        gnupg2 \
        vim \
        zsh

# Install Kubectl
RUN     curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg && \
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list && \
        apt-get update && \
        apt-get install -y kubectl=1.28.4-1.1

# Set zsh as default shell
RUN     chsh -s $(which zsh)

# Install Oh My Zsh
RUN     apt-get install -y zsh && \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Powerlevel10K Theme
RUN     git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Set Powerlevel10K Theme
RUN     sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

# Install ZSH Plugins
RUN     git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set ZSH Plugins
RUN     sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# Copy and source .p10k.zsh
COPY    .p10k.zsh /root/.p10k.zsh
RUN     echo "source ~/.p10k.zsh" >> ~/.zshrc

# Set up KubeCTL welcome message
COPY    20-welcome /etc/update-motd.d/20-welcome
RUN     chmod +x /etc/update-motd.d/20-welcome && \
        echo "/etc/update-motd.d/20-welcome" >> ~/.zshrc && \
        echo exit | script -qec zsh /dev/null

# Set Workdir
WORKDIR /root
