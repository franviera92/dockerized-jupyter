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
LABEL maintainer="cgiraldo@gradiant.org"
LABEL organization="gradiant.org"
ENV JUPYTER_VERSION=5.7.4 JUPYTERLAB_VERSION=0.35.4
# PYTHON layer
RUN set -ex && \
    apk add --no-cache bash \
        build-base \
        python3 \
        python3-dev \
        py3-numpy \
        py-numpy-dev \
        py3-scipy \
        py3-numpy-f2py \
        # matplotlib deps
        freetype-dev \
        libpng-dev \
        # enable NOTEBOOK_URL to get git repos
        git && \
    pip3 install --upgrade pip && \
    pip3 install --no-cache-dir pandas pandasql scikit-learn matplotlib plotly && \
    pip3 install --no-cache-dir notebook==${JUPYTER_VERSION} jupyterlab==${JUPYTERLAB_VERSION} && \
    mkdir /notebooks && mkdir /root/.jupyter && \
    wget https://github.com/jgm/pandoc/releases/download/2.6/pandoc-2.6-linux.tar.gz && \
    tar -xvzf pandoc-2.6-linux.tar.gz && \
    mv pandoc-2.6/bin/pandoc* /usr/local/bin/ && \
    rm -rf pandoc*

COPY jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py
COPY entrypoint.sh /entrypoint.sh

ENV JUPYTER_PORT=8888
ENV JUPYTERLAB=false

VOLUME /notebooks

ENTRYPOINT ["/entrypoint.sh"]

##############################
# R support layers
##############################
COPY --from=R-fs-builder /fs-master.tgz /

RUN apk add autoconf \
            automake \
            build-base \
            R \
            R-dev  automake autoconf libzmq libxml2-dev linux-headers tzdata && \
    apk add msttcorefonts-installer && update-ms-fonts && \
    #fixing error when getting encoding setting from iconvlist" \
    sed -i 's/,//g' /usr/lib/R/library/utils/iconvlist && \
    R -e "install.packages('Rcpp', repos = 'http://cran.us.r-project.org')" && \
    R -e "install.packages('/fs-master.tgz', repos= NULL, type='source')" && \
    rm /fs-master.tgz && \
    R -e "install.packages('IRkernel', repos = 'http://cran.us.r-project.org')" && \
    #R packages for data science (tidyverse)
    R -e "install.packages(c('tidyverse'),repos = 'http://cran.us.r-project.org')"
#R visualization packages
RUN R -e "install.packages(c('ggridges','plotly','leaflet'),\
      repos = 'http://cran.us.r-project.org')"
#R development packages
RUN R -e "install.packages('devtools', repos = 'http://cran.us.r-project.org')"


##############################
# Spark Support layers
##############################

RUN apk add --no-cache openjdk8-jre

ENV JAVA_HOME=/usr/lib/jvm/default-jvm/ \
    SPARK_VERSION=2.4.0 \
    SPARK_HOME=/opt/spark \
    PATH="$PATH:$SPARK_HOME/sbin:$SPARK_HOME/bin" \
    SPARK_URL="local[*]" \
# WARNING py4j version may change depending on SPARK_VERSION
    PYTHONPATH="$SPARK_HOME/python:$SPARK_HOME/python/build:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip:$PYTHONPATH" \
    SPARK_OPTS=""

RUN apk add --no-cache libc6-compat && mkdir /opt && \
wget -qO- https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz | tar xvz -C /opt && \
ln -s /opt/spark-$SPARK_VERSION-bin-hadoop2.7 /opt/spark && \
# findspark to use pyspark with regular ipython kernel. At the beggining of your notebook run
# import findspark
# findspark.init()
# import pyspark
   pip3 install findspark

##############################
# Kafka Support layers
##############################
RUN wget http://central.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.11/$SPARK_VERSION/spark-sql-kafka-0-10_2.11-$SPARK_VERSION.jar \
   -O /opt/spark-$SPARK_VERSION-bin-hadoop2.7/jars/spark-sql-kafka-0-10_2.11-$SPARK_VERSION.jar && \
   wget http://central.maven.org/maven2/org/apache/kafka/kafka-clients/1.0.0/kafka-clients-1.0.0.jar \
   -O /opt/spark-$SPARK_VERSION-bin-hadoop2.7/jars/kafka-clients-1.0.0.jar

#############################
# Extensions layer
#############################
RUN apk add --no-cache libxml2-dev libxslt-dev && pip3 install ipywidgets ipyleaflet beakerx requests jupyter-contrib-nbextensions && \
        cp -r /usr/lib/python3.6/site-packages/beakerx/static/* /usr/share/jupyter/nbextensions/beakerx/ && \
        beakerx install && \
        jupyter contrib nbextension install && \
        ## Fix nbextension tab disappearing https://github.com/Jupyter-contrib/jupyter_nbextensions_configurator/pull/85
        sed -i 's/jqueryui/jquery/g' /usr/lib/python3.6/site-packages/jupyter_nbextensions_configurator/static/nbextensions_configurator/tree_tab/main.js
