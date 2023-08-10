# Pobranie obrazu bazowego
FROM python:3.10

# Skopiowanie kodu źródłowego do kontenera
COPY . /app
WORKDIR /app

# Instalacja zależności
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Otwarcie portu
EXPOSE 5001

# Uruchomienie aplikacji
CMD ["python", "blockchain.py"]