FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install pip & dependencies for rust compiler (needed for s390x image)
RUN microdnf update && \
    microdnf install -y pip gcc libffi-devel python-devel openssl-devel && \
    microdnf clean all 

# FIXME - this should only be needed in s390x environments, slows down builds on other archs
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install ansible-core
RUN source "$HOME/.cargo/env" && pip install ansible-core

# Copy pip & ansible requirement files
WORKDIR $ANSIBLE_HOME
COPY ansible/requirements.txt ansible/requirements.yml $ANSIBLE_HOME
RUN pip install -r requirements.txt
RUN ansible-galaxy collection install -vv -r requirements.yml