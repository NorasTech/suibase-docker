FROM debian:stable-slim

ARG USER=sui
ARG FORCE_TAG

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

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Rust to PATH
ENV PATH="$HOME/.local/bin:$HOME/.cargo/bin:${PATH}"

RUN rustup update stable

# Clone and install suibase
RUN cd ~
RUN git clone https://github.com/chainmovers/suibase.git ./suibase
RUN cd ./suibase && ./install

RUN localnet create

ENV FORCE_TAG=${FORCE_TAG}
ENV config=${HOME}/suibase/workdirs/localnet/suibase.yaml
# if FORCE_TAG is set, then checkout to the specified tag
RUN if [ -n "$FORCE_TAG" ]; then \
  echo '' >> ${config} \
  echo 'force_tag: "${FORCE_TAG}" >> ${config};' \
  localnet update; \
  fi

# Expose ports
EXPOSE 9000
EXPOSE 44340
EXPOSE 44380

ENTRYPOINT ["/bin/bash"]

CMD ["-c", "./start.sh && exec /bin/bash"]
