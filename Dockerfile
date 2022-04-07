FROM registry.access.redhat.com/ubi8/ubi:latest

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini /bin/tini
ADD bin/entrypoint.sh /bin/entrypoint

RUN dnf install -y hostname python3 python3-pip && \
  pip3 install --upgrade pip && \
  pip install ansible jmespath && \
  chmod +x /bin/tini /bin/entrypoint && \
  rm -rf /var/cache/dnf

ENV HOME=/ansible
RUN mkdir -p ${HOME} ${HOME}/.ansible/tmp
COPY . /ansible
RUN chmod -R g+w ${HOME} && chgrp -R root ${HOME}
WORKDIR /ansible


ENTRYPOINT ["entrypoint"]
