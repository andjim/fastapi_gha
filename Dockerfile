FROM python:3.10-slim as base

RUN mkdir /app

WORKDIR /app

COPY ./main.py  .
COPY ./requirements.txt  .

RUN apt-get update && apt-get install -y \
    gcc \
    build-essential \
    && apt-get clean

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

FROM base as test
# just a placeholder for test stage
# you can add test dependencies here if needed
RUN mkdir /test 

FROM base as final

EXPOSE 8000
CMD ["fastapi","run","main.py"] 