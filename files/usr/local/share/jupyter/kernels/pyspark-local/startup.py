import numpy as np
import pandas as pd
import sklearn as skl
import pyspark
import pyspark.sql

conf = pyspark.SparkConf()
conf.setMaster('local[*]')
spark = pyspark.sql.SparkSession.builder.config(conf=conf).getOrCreate()
sc = spark.sparkContext


