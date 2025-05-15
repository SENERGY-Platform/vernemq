FROM erlang:26 as plugin
COPY ./env_api_key_plugin /opt/env_api_key_plugin
WORKDIR /opt/env_api_key_plugin
RUN rebar3 compile

FROM erlang:26 as builder
RUN apt-get update -y
RUN apt-get install -y libsnappy-dev
ENV VERNEMQ=/opt/vernemq
RUN git clone https://github.com/vernemq/vernemq.git $VERNEMQ
WORKDIR /opt/vernemq
RUN git checkout tags/2.0.1
RUN make rel

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get -y install bash procps openssl iproute2 curl jq libsnappy-dev net-tools && \
    rm -rf /var/lib/apt/lists/* && \
    addgroup --gid 10000 vernemq && \
    adduser --uid 10000 --system --ingroup vernemq --home /vernemq --disabled-password vernemq

WORKDIR /vernemq

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR="app=vernemq" \
    DOCKER_VERNEMQ_LOG__CONSOLE=console \
    PATH="/vernemq/bin:$PATH" \
    VERNEMQ_VERSION="2.0.1"

COPY --from=builder /opt/vernemq/_build/default/rel/vernemq /vernemq

COPY --chown=10000:10000 bin/vernemq.sh /usr/sbin/start_vernemq
COPY --chown=10000:10000 files/vm.args /vernemq/etc/vm.args

RUN chmod a+x /usr/sbin/start_vernemq

RUN chown -R 10000:10000 /vernemq && \
    ln -s /vernemq/etc /etc/vernemq && \
    ln -s /vernemq/data /var/lib/vernemq && \
    ln -s /vernemq/log /var/log/vernemq

# Ports
# 1883  MQTT
# 8883  MQTT/SSL
# 8080  MQTT WebSockets
# 44053 VerneMQ Message Distribution
# 4369  EPMD - Erlang Port Mapper Daemon
# 8888  Prometheus Metrics
# 9100 9101 9102 9103 9104 9105 9106 9107 9108 9109  Specific Distributed Erlang Port Range

EXPOSE 1883 8883 8080 44053 4369 8888 \
       9100 9101 9102 9103 9104 9105 9106 9107 9108 9109


VOLUME ["/vernemq/log", "/vernemq/data", "/vernemq/etc"]

HEALTHCHECK CMD vernemq ping | grep -q pong


# env api plugin
RUN mkdir /vernemq/plugins
COPY --from=plugin /opt/env_api_key_plugin/_build/default /vernemq/plugins/envapikey

RUN chmod -R o+w /vernemq/plugins
RUN chmod -R o+r /vernemq/plugins
RUN chown -R vernemq:vernemq /vernemq/plugins


USER vernemq

CMD ["start_vernemq"]

