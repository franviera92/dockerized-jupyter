FROM gradiant/spark:2.4.0 as spark

FROM alpine:3.8 as R-fs-builder
LABEL maintainer="cgiraldo@gradiant.org"
LABEL organization="gradiant.org"

RUN apk add --no-cache autoconf \
                       automake \
                       libtool \
                       linux-headers
#fs-bug https://github.com/r-lib/fs/pull/158. Creating a local Rpackage from latest github sources
RUN wget -O /fs-master.zip https://github.com/r-lib/fs/archive/master.zip
RUN unzip /fs-master.zip && cd /fs-master/src/libuv/ && ./autogen.sh && cd / && tar -cvzf fs-master.tgz fs-master/


FROM alpine:3.8

LABEL maintainer="cgiraldo@gradiant.org" \
      organization="gradiant.org"

ENV JUPYTER_VERSION=5.7.4 \
    JUPYTERLAB_VERSION=0.35.4 \
    JUPYTER_PORT=8888 \
    JUPYTERLAB=false \
    JUPYTERHUB_VERSION=0.9.4 \
    NB_USER=jovyan \
    NB_UID=1000 \
    NB_GID=100 


##############################
# JUPYTER layers
##############################
RUN set -ex && \
    apk add --no-cache bash \
        build-base \
        python3 \
        python3-dev \
        zeromq-dev \
        libxml2-dev \
        libxslt-dev \
        # enable NOTEBOOK_URL to get git repos
        git && \
    pip3 install --no-cache-dir --upgrade pip && \
    # https://github.com/jupyter/notebook/issues/4311
    pip3 install --no-cache-dir tornado==5.1.1 && \
    pip3 install --no-cache-dir notebook==${JUPYTER_VERSION} jupyterlab==${JUPYTERLAB_VERSION} nbgitpuller==0.6.1 ipywidgets jupyter-contrib-nbextensions && \
    jupyter serverextension enable --py nbgitpuller --sys-prefix && \
    jupyter contrib nbextension install && \
    ## Fix nbextension tab disappearing https://github.com/Jupyter-contrib/jupyter_nbextensions_configurator/pull/85
    sed -i 's/jqueryui/jquery/g' /usr/lib/python3.6/site-packages/jupyter_nbextensions_configurator/static/nbextensions_configurator/tree_tab/main.js && \  
    wget https://github.com/jgm/pandoc/releases/download/2.6/pandoc-2.6-linux.tar.gz && \
    tar -xvzf pandoc-2.6-linux.tar.gz && \
    mv pandoc-2.6/bin/pandoc* /usr/local/bin/ && \
    rm -rf pandoc* && \
    # Jupyterhub option
    pip3 install --no-cache-dir jupyterhub==${JUPYTERHUB_VERSION} && \
    apk add --no-cache linux-pam \
                       npm && \
    npm install -g configurable-http-proxy

##############################
# Spark & Kafka Support layers
##############################

ENV JAVA_HOME=/usr/lib/jvm/default-jvm/ \
    SPARK_VERSION=2.4.0 \
    SPARK_HOME=/opt/spark \
    PATH="$PATH:$SPARK_HOME/sbin:$SPARK_HOME/bin" \
    SPARK_URL="local[*]" \
# WARNING py4j version may change depending on SPARK_VERSION
    PYTHONPATH="$SPARK_HOME/python:$SPARK_HOME/python/build:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip:$PYTHONPATH" \
    SPARK_OPTS=""

RUN apk add --no-cache openjdk8-jre libc6-compat nss && mkdir /opt && \
    wget -qO- https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz | tar xvz -C /opt && \
    ln -s /opt/spark-$SPARK_VERSION-bin-hadoop2.7 /opt/spark && \
    wget http://central.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.11/$SPARK_VERSION/spark-sql-kafka-0-10_2.11-$SPARK_VERSION.jar \
    -O /opt/spark-$SPARK_VERSION-bin-hadoop2.7/jars/spark-sql-kafka-0-10_2.11-$SPARK_VERSION.jar && \
    wget http://central.maven.org/maven2/org/apache/kafka/kafka-clients/1.0.0/kafka-clients-1.0.0.jar \
    -O /opt/spark-$SPARK_VERSION-bin-hadoop2.7/jars/kafka-clients-1.0.0.jar
# Copy native libraries from gradiant/spark docker image
COPY --from=spark /lib/libhadoop.* /lib/
COPY --from=spark /lib/libhdfs.* /lib/

##############################
# PYTHON Data-science layers
##############################
COPY files/python/py3-pandas-0.24.1-r0.apk / 
RUN set -ex && \
    apk add --no-cache \
        py3-numpy \
        py-numpy-dev \
        py3-scipy \
        py3-numpy-f2py \
        # matplotlib deps
        freetype-dev \
        libpng-dev \
        # enable NOTEBOOK_URL to get git repos
        git && \
    apk add --allow-untrusted /py3-pandas-0.24.1-r0.apk && rm /py3-pandas-0.24.1-r0.apk && \
    pip3 install --no-cache-dir pandasql scikit-learn matplotlib plotly ipyleaflet && \
    # findspark to use pyspark with regular ipython kernel. At the beggining of your notebook run
    # import findspark
    # findspark.init()
    # import pyspark
    pip3 install findspark

#############################
# BeakerX Extensions for scala kernel
#############################
RUN pip3 install beakerx requests && \
        cp -r /usr/lib/python3.6/site-packages/beakerx/static/* /usr/share/jupyter/nbextensions/beakerx/ && \
        beakerx install

##############################
# R layers
##############################
COPY --from=R-fs-builder /fs-master.tgz /

RUN set -ex && \
    # Thereis a problem installing R openssl package if libssl1.0 package is installed in the system. 
    # as a temporal patch We temporary delete libssl1.0 package and reinstall.
    apk del nodejs npm libssl1.0 libcrypto1.0 &&\
    apk add autoconf \
            automake \
            freetype-dev \
            R \
            R-dev \
            linux-headers \
            tzdata && \
    apk add msttcorefonts-installer && update-ms-fonts && \
    #fixing error when getting encoding setting from iconvlist" \
    sed -i 's/,//g' /usr/lib/R/library/utils/iconvlist && \
    R -e "install.packages('Rcpp', repos = 'http://cran.us.r-project.org')" && \
    R -e "install.packages('/fs-master.tgz', repos= NULL, type='source')" && \
    rm /fs-master.tgz && \
    R -e "install.packages('IRkernel', repos = 'http://cran.us.r-project.org')" && \
    R -e "IRkernel::installspec(user = FALSE)" && \
    #R packages for data science (tidyverse)
    R -e "install.packages(c('tidyverse'),repos = 'http://cran.us.r-project.org')" && \
    #R visualization packages
    R -e "install.packages(c('ggridges','plotly','leaflet'),\
      repos = 'http://cran.us.r-project.org')" && \
    #R development packages
    R -e "install.packages('devtools', repos = 'http://cran.us.r-project.org')" && \
    apk add nodejs npm libssl1.0 libcrypto1.0 


EXPOSE 8888
COPY files/jupyter/ /

ENV HOME=/home/$NB_USER
WORKDIR $HOME
RUN apk add --no-cache shadow sudo && \
    adduser -s /bin/bash -h /home/jovyan -D -G $(getent group $NB_GID | awk -F: '{printf $1}') -u $NB_UID $NB_USER && \
    fix-permissions /home/jovyan

USER $NB_UID


CMD ["start-notebook.sh"]

