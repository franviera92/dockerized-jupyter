import numpy as np
import pandas as pd
import sklearn as skl

import findspark
findspark.init()

import os
import re
import pyspark
import pyspark.sql


'''
Spark on k8s example configuration: This script adds configuration key values from SPARCONF_XX environment variables
conf = pyspark.SparkConf().setAll([('spark.kubernetes.container.image','gradiant/spark:2.4.2-python'),
                                   ('spark.kubernetes.namespace','default'),
                                   ('spark.executor.instances', '1'),
                                   ('spark.kubernetes.executor.request.cores','0.2'),
                                   ('spark.executor.memory', '500M'),
                                   ('spark.kubernetes.driver.pod.name','jupyter-{username}'),
                                   ('spark.master','local[*]')])
'''
conf = pyspark.SparkConf()

if 'SPARKCONF_SPARK_MASTER' in os.environ and 'k8s' in os.environ['SPARKCONF_SPARK_MASTER']:
  if 'SPARKCONF_SPARK_KUBERNETES_DRIVER_POD_NAME' not in os.environ:
    os.environ['SPARKCONF_SPARK_KUBERNETES_DRIVER_POD_NAME'] = os.environ.get("HOSTNAME","")

for key in os.environ:
  if 'SPARKCONF_' in key:
    value = os.environ.get(key)
    key = key.replace('SPARKCONF_','').replace('_','.').lower()
    conf = conf.set(key,value)


spark = pyspark.sql.SparkSession.builder.config(conf=conf).getOrCreate()
sc = spark.sparkContext


