# Jupyter for Big Data Analytics
This is a lightweight Jupyter Docker Image for Big Data Analytics.

It includes support for: 
- Apache Spark 2.4.4
- Python3.7.
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
- Apache Toree for Spark Kernel

## Quick Start

```
docker run -p 8888:8888 -d gradiant/jupyter
```

Browse [http://localhost:8888](http://localhost:8888)


## Configuration

Configuration is set by the following environment variables:

| Variables    | Default  | Description |
| ------------ | -------- | ----------- |
| JUPYTER_ENABLE_LAB | true   | enables the next-generation user interface for Project Jupyter. |
| JUPYTER_PORT | 8888     | binding port of jupyter http server  |


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

The image includes Spark 2.4.4 support through Apache Toree Kernels.
