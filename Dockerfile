#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# WARNING: THIS DOCKERFILE IS NOT INTENDED FOR PRODUCTION USE OR DEPLOYMENT. AT
#          THIS POINT, THIS IS ONLY INTENDED FOR USE IN AUTOMATED TESTS.

FROM ubuntu:xenial

USER root

ENV DEBIAN_FRONTEND noninteractive
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8

ENV HADOOP_VERSION 2.6.0
ENV HADOOP_DISTRO=cdh
ENV HADOOP_HOME=/tmp/hadoop-${HADOOP_DISTRO}
ENV HIVE_HOME=/tmp/hive
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

RUN  mkdir ${HADOOP_HOME} && \
     mkdir ${HIVE_HOME}  && \
     mkdir /tmp/minicluster  && \
     mkdir -p /user/hive/warehouse && \
     chmod -R 777 ${HIVE_HOME} && \
     chmod -R 777 /user/

# Add nodejs repo and key
ADD nodesource.gpg.key /tmp/nodesource.gpg.key
RUN apt-key add /tmp/nodesource.gpg.key
RUN echo 'deb http://deb.nodesource.com/node_8.x xenial main' > /etc/apt/sources.list.d/nodesource.list
RUN echo 'deb-src http://deb.nodesource.com/node_8.x xenial main' >> /etc/apt/sources.list.d/nodesource.list

RUN apt-get update && apt-get install --no-install-recommends -y \
      openjdk-8-jdk \
      wget curl \
      gcc \
      g++ \
      python-dev \
      python3-dev \
      python-pip \
      python3-pip \
      python-virtualenv \
      python3-venv \
      python-setuptools \
      python-pkg-resources \
      python3-setuptools \
      python3-pkg-resources \
      make \
      nodejs \
      vim \
      less \
      git \
      unzip \
      sudo \
      ldap-utils \
      mysql-client-core-5.7 \
      mysql-client-5.7 \
      libmysqlclient-dev \
      postgresql-client \
      sqlite3 \
      libkrb5-dev \
      libsasl2-dev \
      krb5-user \
      openssh-client \
      openssh-server \
      python-selinux \
      sasl2-bin \
      libsasl2-2 \
      libsasl2-dev \
      libsasl2-modules \
      locales \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install Hadoop
# --absolute-names is a work around to avoid this issue https://github.com/docker/hub-feedback/issues/727
RUN cd /tmp && \
    wget -q https://archive.cloudera.com/cdh5/cdh/5/hadoop-${HADOOP_VERSION}-cdh5.11.0.tar.gz && \
    tar xzf hadoop-${HADOOP_VERSION}-cdh5.11.0.tar.gz --absolute-names --strip-components 1 -C $HADOOP_HOME && \
    rm hadoop-${HADOOP_VERSION}-cdh5.11.0.tar.gz

# Install Hive
RUN cd /tmp && \
    wget -q https://archive.cloudera.com/cdh5/cdh/5/hive-1.1.0-cdh5.11.0.tar.gz && \
    tar xzf hive-1.1.0-cdh5.11.0.tar.gz --strip-components 1 -C $HIVE_HOME && \
    rm hive-1.1.0-cdh5.11.0.tar.gz

# Install MiniCluster
RUN cd /tmp && \
    wget -q https://github.com/bolkedebruin/minicluster/releases/download/1.1/minicluster-1.1-SNAPSHOT-bin.zip && \
    unzip minicluster-1.1-SNAPSHOT-bin.zip -d /tmp && \
    rm minicluster-1.1-SNAPSHOT-bin.zip

RUN adduser airflow && \
    echo "airflow ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/airflow && \
    chmod 0440 /etc/sudoers.d/airflow

# Install Python requirements
RUN sudo -H pip install --upgrade pip && \
    sudo -H pip install wheel tox && \
    sudo -H pip3 install --upgrade pip && \
    sudo -H pip3 install wheel tox && \
    rm -rf ~/.cache

EXPOSE 8080

WORKDIR /home/airflow

ENV PATH "$PATH:/tmp/hive/bin:$ADDITIONAL_PATH"

USER airflow
