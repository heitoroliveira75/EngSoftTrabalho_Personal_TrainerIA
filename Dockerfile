FROM python:3.10-slim

# Instala dependências do sistema operacional necessárias para o MediaPipe e OpenCV no Linux
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libgles2 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia requisitos e instala dependências Python
COPY BD/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copia o código do projeto
COPY . .

# Configura porta padrão
ENV PORT=8000
EXPOSE 8000

# Executa o servidor FastAPI
CMD ["sh", "-c", "uvicorn BD.api:app --host 0.0.0.0 --port ${PORT:-8000}"]
