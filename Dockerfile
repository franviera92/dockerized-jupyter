FROM debian:buster-slim

LABEL maintainer="cgiraldo@gradiant.org" \
      organization="gradiant.org"

ENV JUPYTER_VERSION=6.0.1 \
    JUPYTERLAB_VERSION=1.1.4 \
    JUPYTER_PORT=8888 \
    JUPYTER_ENABLE_LAB=true \
    JUPYTERHUB_VERSION=1.0.0 


##############################
# JUPYTER Python DataScience layer
##############################

RUN apt update && apt install -y python3 python3-dev python3-pip git sudo && rm -rf /var/lib/apt/lists/* && \
    pip3 install --no-cache-dir --upgrade pip setuptools 
    # pip3 installing tfx error ERROR: apache-beam 2.15.0 has requirement httplib2<=0.12.0,>=0.8, but you'll have httplib2 0.14.0 which is incompatible.
RUN    pip3 install --no-cache-dir httplib2==0.12.0 && \
    pip3 install --no-cache-dir notebook==$JUPYTER_VERSION jupyterlab==$JUPYTERLAB_VERSION nbgitpuller==0.7.2 && \
    jupyter serverextension enable --py nbgitpuller --sys-prefix && \
    # tfx already install pyarrow scipy pandas scikit-learn hdfs, avro-python3 pymongo etc.
    pip3 install --no-cache-dir tensorflow==1.14.0 tfx==0.14.0 matplotlib==3.1.1 && \
    pip3 install kafka-python==1.4.7 && \
    # Jupyterhub option
    apt update && apt install -y npm nodejs && rm -rf /var/lib/apt/lists/* && \
    pip3 install --no-cache-dir jupyterhub==${JUPYTERHUB_VERSION} && \
    npm install -g configurable-http-proxy
    #apk add --no-cache linux-pam \
    #                   npm && \
    #npm install -g configurable-http-proxy


##############################
# R layer
##############################

RUN apt update && apt install -y r-base r-base-dev libxml2-dev && rm -rf /var/lib/apt/lists/* && \
    R -e "install.packages('IRkernel', repos = 'http://cran.us.r-project.org')" && \
    R -e "IRkernel::installspec(user = FALSE)" && \
    apt update && apt install -y libcurl4-openssl-dev libssl-dev && rm -rf /var/lib/apt/lists/* && \
    R -e "install.packages(c('tidyverse'),repos = 'http://cran.us.r-project.org')" && \
    R -e "install.packages('devtools', repos = 'http://cran.us.r-project.org')"

##############################
# Spark Support layer
##############################
# Installed openjdk-8 since spark 2.4.4 does not yet support Java 11
# need unstable repo from debian buster

ENV JAVA_HOME=/usr/lib/jvm/default-jvm/ \
    SPARK_VERSION=2.4.4 \
    SPARK_HOME=/opt/spark
ENV PATH="$PATH:$SPARK_HOME/sbin:$SPARK_HOME/bin" \
    SPARK_URL="local[*]" \
    PYTHONPATH="${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-src.zip:$PYTHONPATH" \
    SPARK_OPTS="" \
    PYSPARK_PYTHON=/usr/bin/python3 

RUN mkdir -p /usr/share/man/man1 && \
    echo "deb http://deb.debian.org/debian unstable main" > /etc/apt/sources.list.d/91-unstable.list && \
    apt update && apt install -y openjdk-8-jre-headless wget && rm /etc/apt/sources.list.d/91-unstable.list && rm -rf /var/lib/apt/lists/* && \
    cd /usr/lib/jvm && ln -s java-8-openjdk-amd64 default-jvm && \
    wget -qO- https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz | tar xvz -C /opt && \
    ln -s /opt/spark-$SPARK_VERSION-bin-hadoop2.7 /opt/spark && \
    cd /opt/spark/python/lib && ln -s py4j-*-src.zip py4j-src.zip


#####################################
# Scala kernel (Toree)
#####################################
RUN pip3 install toree==0.3.0 && \
    jupyter toree install --kernel_name="Spark - Local" --spark_home=${SPARK_HOME} && \
    jupyter toree install --kernel_name="Spark - Cluster" --spark_home=${SPARK_HOME} --spark_opts='--master=${SPARKCONF_SPARK_MASTER}'


##############################
# tools layer
##############################
#
# ADDING KAFKA LIBRARIES
#RUN wget http://central.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/$SPARK_VERSION/spark-sql-kafka-0-10_2.12-$SPARK_VERSION.jar \
#    -O /opt/spark/jars/spark-sql-kafka-0-10_2.12-$SPARK_VERSION.jar && \
#    wget http://central.maven.org/maven2/org/apache/kafka/kafka-clients/2.0.0/kafka-clients-2.0.0.jar \
#    -O /opt/spark/jars/kafka-clients-2.0.0.jar
RUN pip3 install mlflow==1.3.0

# create a user, since we don't want to run as root
ENV NB_USER=jovyan
ENV NB_UID=1000
ENV NB_GID=100
ENV HOME=/home/jovyan
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER
WORKDIR $HOME
COPY files /
#USER jovyan

CMD ["start-notebook.sh"]
