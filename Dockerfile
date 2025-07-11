FROM python:3.10-slim

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

EXPOSE 8000

CMD ["fastapi","run","main.py"]  