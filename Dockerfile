FROM ubuntu:22.04

ARG BYOND_MAJOR=516
ARG BYOND_MINOR=1663

ENV DEBIAN_FRONTEND=noninteractive

# Enable i386 architecture for BYOND 32-bit binaries
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        make \
        libc6:i386 \
        libstdc++6:i386 \
        zlib1g:i386 \
        libmysqlclient21:i386 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/lib/i386-linux-gnu/libmysqlclient.so.21 /usr/lib/i386-linux-gnu/libmysqlclient.so

# Install BYOND
RUN mkdir -p /opt/byond && \
    cd /opt/byond && \
    curl -L "https://cdn.taucetistation.org/byond/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" \
        -o byond.zip -A "TauCetiStation/1.0" && \
    unzip byond.zip && \
    rm byond.zip && \
    cd byond && \
    make here

ENV PATH="/opt/byond/byond/bin:${PATH}"

WORKDIR /ss13

COPY . .

RUN chmod +x docker-entrypoint.sh

# Compile the project
RUN bash -c "source /opt/byond/byond/bin/byondsetup && DreamMaker taucetistation.dme"

EXPOSE 1488

ENTRYPOINT ["./docker-entrypoint.sh"]
