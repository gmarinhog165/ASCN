FROM python:3.11.5-slim

WORKDIR /app

COPY ./moonshot-main .

COPY ./.env /app/

RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir -r requirements.txt

CMD ["sh", "-c", "python manage.py migrate && python seed.py && python manage.py runserver 0.0.0.0:8000"]

