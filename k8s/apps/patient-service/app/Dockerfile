FROM python:3.12-slim

RUN useradd -m -u 10001 appuser

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

USER 10001
EXPOSE 8080

ENV PYTHONUNBUFFERED=1
ENV APP_VERSION=0.1.0

CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app", "--workers=2", "--threads=4"]
