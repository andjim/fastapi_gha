FROM python:3.10-alpine

RUN mkdir app

WORKDIR app

COPY ./main.py  .
COPY ./requirements.txt  .

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

EXPOSE 8000

CMD ["fastapi","run","main.py"]  