# FROM pytorch/pytorch:1.10.0-cuda11.3-cudnn8-devel
FROM swift:swift:5.8.1

ARG USERNAME=yi
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV TZ=Asia/Shanghai
ENV TERM=xterm-256color
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub 298
# RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/7fa2af80.pub
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4B469963BF863CC
# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
    # && git config --global core.autocrlf true


# /etc/lsb-release is checked inside the container and sets DISTRIB_RELEASE.
# We need `[` instead of `[[` because the shell is `/bin/sh`.
# shellcheck disable=SC1091,SC2154,SC2292

# install lsb-release, which will be use by oh-my-tuna
# RUN apt-get update \
#   && apt-get install -y lsb-release python3.8
# RUN wget https://tuna.moe/oh-my-tuna/oh-my-tuna.py \
#   && sudo python3 oh-my-tuna.py --global -y

 # 设置X11转发(把/etc/ssh/sshd_config 中的X11Forwarding置为yes,X11UseLocalhost置为no)
# RUN sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config && \
#     sed -i "s/^.*X11UseLocalhost.*$/X11UseLocalhost no/" /etc/ssh/sshd_config
# EXPOSE 22


# RUN apt-get update \
#   && apt-get install -y --no-install-recommends software-properties-common gnupg-agent \
#   && add-apt-repository -y ppa:git-core/ppa \
#   && apt-get update \
#   && apt-get install -y --no-install-recommends \
#   acl \
#   bzip2 \
#   ca-certificates \
#   curl \
#   file \
#   fonts-dejavu-core \
#   g++ \
#   gawk \
#   git \
#   gpg \
#   less \
#   libz-dev \
#   locales \
#   make \
#   netbase \
#   openssh-client \
#   openssh-server \
#   patch \
#   sudo \
#   unzip \
#   uuid-runtime \
#   tzdata \
#   jq \
#   && if [ "$(. /etc/lsb-release; echo "${DISTRIB_RELEASE}" | cut -d. -f1)" -ge 22 ]; then apt-get install -y --no-install-recommends skopeo; fi \
#   && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
#   && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
#   && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
#   && apt-get update \
#   && apt-get install -y --no-install-recommends gh \
#   && apt-get remove --purge -y software-properties-common \
#   && apt-get autoremove --purge -y \
#   && rm -rf /var/lib/apt/lists/* \
#   && sed -i -E '/^session optional\s+pam_umask\.so$/ s/$/ umask=0022/' /etc/pam.d/common-session \
#   && sed -i -E '/^session optional\s+pam_umask\.so$/ s/$/ umask=0022/' /etc/pam.d/common-session-noninteractive \
#   && localedef -i en_US -f UTF-8 en_US.UTF-8 \
#   && su - $USERNAME

RUN su - $USERNAME
WORKDIR /home/$USERNAME

USER $USERNAME

# RUN mkdir -p /home/yi/.config/tmux
# RUN touch /home/yi/.config/tmux/tmux.conf
# RUN chmod -R 777 /home/yi/.config

# make env function right when ssh to docker
# RUN sed -i '$a\export $(cat /proc/1/environ |tr "\\0" "\\n" | xargs)' .bashrc

# RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
#   && (echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/yi/.profile
# SHELL ["/bin/bash", "-c"]
# RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" \
#   # && eval "$(/home/yi/.linuxbrew/bin/brew shellenv)" \
#   && brew install tmux \
#   && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
#   # && brew install starship \
#   # && eval "$(starship init bash)" \
#   # && brew install pipx \
#   # && pipx ensurepath \
#   # && pipx install nvtop \
#   # && pipx install gpustat
#   # && test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)" \
#   # && test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" \
#   # && test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bash_profile \
#   # && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile \
# # [Optional] Set the default user. Omit if you want to keep the default as root.

# # ENV PATH="/home/yi/.linuxbrew/bin:${PATH}"

# # USER $USERNAME
# # RUN pipx install nvtop \
#   && pipx instal gpustat
ENV PATH="/home/yi/.linuxbrew/bin:${PATH}"

USER $USERNAME
