FROM python:3.12-slim

WORKDIR /app
COPY services/forgeworks-achievements/forgeworks_achievements.py /app/forgeworks_achievements.py
COPY config/achievements /app/achievement-sets

ENV FORGEWORKS_HOST=0.0.0.0
ENV FORGEWORKS_PORT=8080
ENV FORGEWORKS_DATA=/data
ENV FORGEWORKS_ACHIEVEMENT_SETS_DIR=/app/achievement-sets

EXPOSE 8080
CMD ["python3", "/app/forgeworks_achievements.py"]
