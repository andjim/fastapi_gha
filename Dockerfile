FROM python:3.12-slim AS base

RUN mkdir /app

WORKDIR /app

COPY ./main.py  .
COPY ./requirements.txt  .
RUN touch __init__.py

RUN apt-get update && apt-get install -y \
    gcc \
    build-essential \
    && apt-get clean

RUN pip install --upgrade pip
RUN pip install -r requirements.txt
EXPOSE 8000
#============================================================
FROM base AS test
# This stage is for running tests and development dependencies
COPY ./requirements-dev.txt  .
COPY ./test_main.py  .
RUN pip install -r requirements-dev.txt
CMD ["fastapi","dev","main.py"]
#============================================================
FROM base as final
CMD ["fastapi","run","main.py"]