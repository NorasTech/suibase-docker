FROM debian:stable-slim

ARG USER=sui

# Set environment variables
ENV USER=${USER}
ENV HOME=/home/${USER}

# Create user and setup permissions on /etc/sudoers
RUN apt-get update && apt-get install -y sudo

RUN useradd -m -s /bin/bash ${USER}

RUN usermod -aG sudo ${USER}

RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USER} && chmod 0440 /etc/sudoers.d/${USER}

RUN echo "${USER}:${USER}" | chpasswd

# Copy start.sh to home directory and make it executable
COPY start.sh /home/${USER}/start.sh
RUN chmod +x /home/${USER}/start.sh
RUN chown ${USER}:${USER} /home/${USER}/start.sh

# Switch to user
USER ${USER}
WORKDIR ${HOME}

# Install dependencies
RUN sudo apt-get update && sudo apt-get install -y \
  lsof curl git-all cmake gcc libssl-dev pkg-config libclang-dev libpq-dev build-essential

# Install npm and sui-explorer-local
RUN sudo apt-get install -y npm && \
  sudo npm install -g n && \
  sudo n stable && \
  sudo npm install -g sui-explorer-local

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust to PATH
ENV PATH="$HOME/.local/bin:$HOME/.cargo/bin:${PATH}"

RUN rustup update stable

# Clone and install suibase
RUN cd ~
RUN git clone https://github.com/chainmovers/suibase.git ./suibase
RUN cd ./suibase && ./install

# Run localnet for once then exit
RUN localnet start && localnet stop

# Start sui-explorer-local for once then exit
RUN sui-explorer-local start && sui-explorer-local stop

# Expose ports
EXPOSE 9000
EXPOSE 44340
EXPOSE 9001

ENTRYPOINT ["/bin/bash"]

CMD ["-c", "./start.sh && exec /bin/bash"]