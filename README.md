# Jupyter for Big Data Analytics
This is a lightweight Jupyter Docker Image for Big Data Analytics.

It includes support for: 
- Apache Spark 2.4.
- Python3.6.
  - numpy.
  - scipy.
  - pandas.
  - pandasql
  - scikit-learn.
  - matplotlib and plotly for visualization.
- R 3.5.
  - tidyverse.
  - devtools.
  - ggridges ,plotly, leaflet for visualization.
- Jupyterlab next-generation notebook environment.
- [BeakerX extensions](http://beakerx.com/)


## Quick Start

```
docker run -p 8888:8888 -d gradiant/jupyter
```

Browse [http://localhost:8888](http://localhost:8888)


## Configuration

Configuration is set by the following environment variables:

| Variables    | Default  | Description |
| ------------ | -------- | ----------- |
| JUPYTERLAB  | false    | enables the next-generation user interface for Project Jupyter. |
| JUPYTER_PORT | 8888     | binding port of jupyter http server  |
| NOTEBOOKS_URL | (empty) | url to download notebooks to add to /notebooks dir. It can be a .zip .tar.gz .ipynb or a git repo |

**Examples**

Enabling JuypterLab:

```
docker run -p 8888:8888 -e JUPYTERLAB=true -d gradiant/jupyter
```

Prepopulate notebooks dir with git repo contents:

```
docker run -p 8888:8888 -e NOTEBOOKS_URL=https://github.com/Gradiant/notebooks.git -d gradiant/jupyter
```

## Notebook Persistence

Notebooks are stored in ```/notebooks``` image path.
If you want to persist the notebooks you can use docker volumes or bind mounts.

With [docker volumes](https://docs.docker.com/storage/volumes/):

```
docker run -p 8888:8888 -v notebooks:/notebooks -d gradiant/jupyter
```

With [bind mounts](https://docs.docker.com/storage/bind-mounts/):

```
docker run -p 8888:8888  -v "$(pwd)"/notebooks:/notebooks -d gradiant/jupyter
```


## Spark Support

The image includes Spark 2.4.0 support for scala, python and R.

**scala**

BeakerX Scala and Java Kernels provides support for Spark.


**python**

pyspark can be used in regular python3 notebooks if you provide the following initial cell:

```
import findspark
findspark.init()
```

You can set the an external spark cluster when creating the SparkContext in your notebook:
```
import pyspark
pyspark.SparkContext("spark://spark-master.example.com:7077")
```
