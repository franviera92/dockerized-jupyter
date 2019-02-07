#!/bin/sh

if ! [[ -z "$NOTEBOOKS_URL" ]] ; then
    if [ ${NOTEBOOKS_URL: -7} == ".tar.gz" ] ; then
        echo "Downloading and untaring $NOTEBOOKS_URL"
        wget -O /tmp/notebooks.tar.gz $NOTEBOOKS_URL &>/dev/null
        if [ $? -ne 0 ]; then
           echo "Error downloading $NOTEBOOKS_URL"
        else
           tar -xvzf /tmp/notebooks.tar.gz -C /notebooks &>/dev/null
        fi
    elif  [ ${NOTEBOOKS_URL: -4} == ".zip" ] ; then
        echo "Downloading and unziping $NOTEBOOKS_URL"
        wget -O /tmp/notebooks.zip $NOTEBOOKS_URL &>/dev/null
        if [ $? -ne 0 ]; then
           echo "Error downloading $NOTEBOOKS_URL"
        else
           unzip /tmp/notebooks.zip -d /notebooks
        fi
    elif  [ ${NOTEBOOKS_URL: -6} == ".ipynb" ] ; then
        cd /notebooks
        echo "Downloading notebook $NOTEBOOKS_URL"
        wget $NOTEBOOKS_URL &>/dev/null
        if [ $? -ne 0 ]; then
           echo "Error downloading $NOTEBOOKS_URL"
        fi
     elif  [ ${NOTEBOOKS_URL: -4} == ".git" ] ; then
        cd /notebooks
        echo "Checking out notebooks from git repository"
        git clone $NOTEBOOKS_URL &>/dev/null
        if [ $? -ne 0 ]; then
           echo "Error cloning $NOTEBOOKS_URL"
        fi
    else
        echo "WARNING: only .tar.gz or .zip NOTEBOOK_URL are supported"
    fi
  unset -v NOTEBOOKS_URL
fi

if [ "$JUPYTERLAB" = true ]; then
   jupyter lab --ip=0.0.0.0 --allow-root --port $JUPYTER_PORT
else
  jupyter notebook --ip=0.0.0.0 --allow-root --port $JUPYTER_PORT
fi
