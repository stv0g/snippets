FROM python:3.8-slim

RUN mkdir /app
ADD . /app

RUN pip3 install /app

ENTRYPOINT [ "/usr/local/bin/accelerated_exporter" ]
